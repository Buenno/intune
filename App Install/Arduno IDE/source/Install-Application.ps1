$ErrorActionPreference = 'Stop'

function Add-StatusRegistryProperty {
    <#
    .SYNOPSIS
    Adds an application status value to the registry.

    .DESCRIPTION
    Adds an application installation status value to the registry based on the supplied parameters, creates a parent key using the application name if required.
    
    .PARAMETER Application
    The name of the application. 

    .PARAMETER Operation
    The name of the operation your would like to add the status for.

    .PARAMETER Status
    The status of the operation. Valid values are "0" = Failed, and "1" = Success.
    
    .OUTPUTS
    None

    .EXAMPLE
    Add-StatusRegistryProperty -Application "Google Chrome" -Operating "Application Configuration" -Status "1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Application,
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        [Parameter(Mandatory = $true)]
        [ValidateSet("0","1")]
        [string]$Status
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        $statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$Application"
        # Create status registry key if it doesn't exist
        if (!(Test-Path $statusReg)){
            New-Item -Path $statusReg -Force | Out-Null
        }
    }
    PROCESS {
        # Add status value to registry  
        New-ItemProperty -Path $statusReg -Name $Operation -Value $Status -PropertyType String -Force | Out-Null
    }
}

function Remove-StatusRegistryKey {
    <#
    .SYNOPSIS
    Removes an application status key from the registry.

    .DESCRIPTION
    Removes an application installation status key from the registry based on the supplied application name.

    .PARAMETER Application
    The name of the application as listed in the registry.
    
    .OUTPUTS
    None

    .EXAMPLE
    Remove-StatusRegistryKey -Application "Google Chrome"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Application
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }
    PROCESS {
        $statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$Application"
        if ((Test-Path $statusReg)){
            Remove-Item -Path $statusReg -Recurse -Force
        }
    }
} 

function New-NetFirewallRuleAllUsers {
    <#
    .SYNOPSIS
    Creates an inbound or outbound firewall rule for all users.

    .DESCRIPTION
    Creates an inbound or outbound firewall rule for all users that have already logged into the machine (checks user folder). This should only be used for rules which need to be created for program file stored in the user profile.
    
    .PARAMETER DisplayName
    Specifies that only matching firewall rules of the indicated display name are created.

    .PARAMETER Description
    Specifies that matching firewall rules of the indicated description are created.

    .PARAMETER Direction
    Specifies that matching firewall rules of the indicated direction are created. This parameter specifies which direction of traffic to match with this rule. The acceptable values for this parameter are: Inbound or Outbound. The default value is Inbound.

    .PARAMETER Profile
    Specifies one or more profiles to which the rule is assigned. The rule is active on the local computer only when the specified profile is currently active. This relationship is many-to-many and can be indirectly modified by the user, by changing the Profiles field on instances of firewall rules. Only one profile is applied at a time. The acceptable values for this parameter are: Any, Domain, Private, Public, or NotApplicable. The default value is Any.

    .PARAMETER Program
    Specifies the path and file name of the program for which the rule allows traffic. This is specified as the full path to an application file MINUS the path to the user profile directory.

    .PARAMETER Action
    Specifies that matching firewall rules of the indicated action are created. This parameter specifies the action to take on traffic that matches this rule. The acceptable values for this parameter are: Allow or Block. The default value is Allow.

    .PARAMETER Protocol
    Specifies that network packets with matching IP addresses match this rule. This parameter specifies the protocol for an IPsec rule. The acceptable values for this parameter are: Any, TCP, or UDP. The default value is Any.
    
    .PARAMETER LocalPort
    Specifies that network packets with matching IP local port numbers match this rule. The acceptable value is a port or range.

    .PARAMETER RemotePort
    Specifies that network packets with matching IP port numbers match this rule. This parameter value is the second end point of an IPsec rule. The acceptable value is a port or range.
    
    .OUTPUTS
    None

    .EXAMPLE
    New-NetFirewallRuleAllUsers -DisplayName "My FW Rule" -Direction "Inbound" -Profile "Domain" -Program "\appdata\local\app\binary.exe" -Action "Allow"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Inbound","Outbound")]
        [string]$Direction = "Inbound",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Any","Domain", "Private", "Public", "NotApplicable")]
        [string]$Profile = "Any",
        [Parameter(Mandatory = $true)]
        [string]$Program,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Allow","Block")]
        [string]$Action = "Allow",
        [Parameter(Mandatory = $false)]
        [ValidateSet("Any","TCP", "UDP")]
        [string]$Protocol = "Any",
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 65535)]
        [string]$LocalPort,
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 65535)]
        [string]$RemotePort        
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop 

        # Regex for account type, for matching on later
        $sidToMatch = @(
            "S-1-5-21-\d+-\d+\-\d+\-\d+$" # AD user
            "S-1-12-1-\d+-\d+\-\d+\-\d+$" # Entra user
        )
        $sidRegex = $sidToMatch -join "|"
    }   
    PROCESS {
        # Get a list of user profiles
        $profiles = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Where-Object {$_.PSChildName -match $sidRegex}
        
        # Create a custom hash table of parameters for future splatting
        $parameterList = (Get-Command -Name $MyInvocation.InvocationName).Parameters

        foreach ($user in $profiles){
            $params = @{}
            foreach ($key in $parameterList.keys){
                $keyVar = Get-Variable -Name $key -ErrorAction SilentlyContinue
                if ($keyVar.Name -eq "Program"){
                    $programPath = $keyVar.Value.TrimStart("\")
                    $params.Add($keyVar.Name, "$($user.ProfileImagePath)\$programPath")
                }
                elseif ($keyVar.Value){
                    $params.Add($keyVar.Name, $keyVar.Value)
                }
            }
            # Apprend the users name to the DisplayName
            $username = ($user.ProfileImagePath -split '\\')[2]
            $params["DisplayName"] = "$($params.DisplayName) - for $username"
            
            # Add the new firewall rule
            $existingRule = Get-NetFirewallRule -DisplayName $params["DisplayName"] -ErrorAction SilentlyContinue

            if (!($existingRule)){
                New-NetFirewallRule @params
            }
        }
    }
}

function Copy-ItemAllUsers {
    <#
    .SYNOPSIS
    Copies a file/folder to all users.

    .DESCRIPTION
    Copies a file/folder to all user profile folders on the device. Works with Default, AD, and Entra users. 
    
    .PARAMETER Path
    The path to the source file/folder. 

    .PARAMETER Destination
    The destination you would like to copy the file/folder to, relative to the user profile path.

    .PARAMETER IncludeDefault
    Copies file/folder to Default user profile.
    
    .OUTPUTS
    None

    .EXAMPLE
    Copy-ItemToAllUsers -Path \MyConfigFiles -Destination Appdata\Roaming\ -IncludeDefault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [switch]$IncludeDefault
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        
        # Regex for account type, for matching on later
        $sidToMatch = @(
            "S-1-5-21-\d+-\d+\-\d+\-\d+$" # AD user
            "S-1-12-1-\d+-\d+\-\d+\-\d+$" # Entra user
        )
        $sidRegex = $sidToMatch -join "|"

        # Init an array list for storing profile data
        [System.Collections.ArrayList]$profileList = @()

        # Get profile data
        $profiles = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Where-Object {$_.PSChildName -match $sidRegex}
        foreach ($profile in $profiles){
            $user = [pscustomobject]@{
                SID = $profile.PSChildName
                ProfilePath = "$($profile.ProfileImagePath)"
            }
            $profileList.Add($user) | Out-Null
        }

        # Add the default user 
        if ($IncludeDefault){
            $defaultUser = [pscustomobject]@{
                SID = "defaultuser"
                ProfilePath = "$env:SystemDrive\Users\Default"
            }
            $profileList.Add($defaultUser) | Out-Null
        }
    }
    PROCESS {
        # Trim any leading backslash from destination string
        $Destination = $Destination.TrimStart("\")
        foreach ($profile in $profileList){
            # Create destination directory if required, then copy data from source
            if (!(Test-Path "$($profile.ProfilePath)\$Destination")){
                New-Item -Path "$($profile.ProfilePath)\$Destination" -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path $Path -Destination "$($profile.ProfilePath)\$Destination" -Recurse -Force | Out-Null
        }
    }
}

# Application details
$appName =      "Arduino IDE"
$installer =    "msiexec.exe"
#$localDir =     "$env:PROGRAMDATA\Arduino"

# Source files
$binary =       Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$transform =    Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.mst
$script =       Get-ChildItem -Path "$PSScriptRoot\scripts" -Filter *.ps1
$certificates = Get-ChildItem -Path "$PSScriptRoot\config\certificates" -Filter *.cer
$drivers =      Get-ChildItem -Path "$PSScriptRoot\drivers" -Filter *.inf -Recurse
#$cliConfig =    Get-ChildItem -Path "$PSScriptRoot\config\" -Filter *.yaml

# Operations to log in the registry
$installOp =    "Installation"
#$confOp =       "Yaml Configuration Copied"
#$coreOp =       "AVR Core Installed"
$driverOp =     "Drivers Installed"
$certsOp =      "Certificates Installed"
$ideFWOp =      "IDE Firewall Rules Created"   
$mdnsFWOp =     "mDNS Firewall Rules Created"
$scriptOP =     "Script Copied to Local Storage"
$sTaskOp =      "Scheduled Task Created"

# Remove existing status registry key
Remove-StatusRegistryKey -Application $appName

# Install publisher certs
$certStorePath = 'Cert:\LocalMachine\TrustedPublisher'
foreach ($cert in $certificates){
    $certParams = @{
        FilePath = $cert.FullName
        CertStoreLocation = $certStorePath
    }
    try {
        Import-Certificate @certParams
    }
    catch [System.UnauthorizedAccessException] {
		$CertStore = Get-Item $certStorePath
		$CertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadWrite")
		$CertStore.Add($cert.FullName)
		$CertStore.Close()
    }
    catch {
        Write-Error $_
        break
    }
}

Add-StatusRegistryProperty -Application $appName -Operation $certsOp -Status 0

# Install app
$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "ALLUSERS=1",
    "TRANSFORMS=$($transform.FullName)"
)

$i = Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait
if ($i.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status 0
}

<#
# Create app directories 
$createDirs = @(
    "data",
    "libraries"
)

if (Test-Path -Path $localDir){
    Remove-Item -Path $localDir -Recurse -Force
}

foreach ($dir in $createDirs){
    New-Item -Path "$localDir\$dir" -ItemType Directory -Force 
}

# Set the arduino-cli config file paths and write to local storage
$cliData = Get-Content -Path $cliConfig.FullName
$cliData = $cliData.Replace("{0}", "$localDir")
$cliData | Out-File -FilePath "$localdir\$($cliConfig.Name)" -Encoding utf8 -Force

# Copy arduino-cli configuration file to all user inc. default
Copy-ItemAllUsers -Path "$localdir\$($cliConfig.Name)" -Destination ".arduinoIDE" -IncludeDefault
Add-StatusRegistryProperty -Application $appName -Operation $confOp -Status 0

# Install Arduino AVR core via CLI
$coreParams = @(
    "--config-file ""$localDir\$($cliConfig.Name)""",
    "core install arduino:avr"
)

$cliBinary =    "$env:ProgramFiles\arduino-ide\resources\app\lib\backend\resources\arduino-cli.exe"


$c = Start-Process $cliBinary -ArgumentList "$($coreParams -join " ")" -PassThru -Wait
if ($c.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $coreOp -Status 0
}

$driverBinary =  Get-ChildItem -Path "$localDir\data\packages\arduino\hardware\avr\1.8.6\drivers\" -Filter *64.exe
#>

# Install driver packages
$driverCount = 0

foreach ($driver in $drivers){
    $driverParams = @(
        "/add-driver",
        "`"$($driver.FullName)`"",
        "/install"
    )
    $d = Start-Process "C:\Windows\System32\pnputil.exe" -ArgumentList "$($driverParams -join " ")" -PassThru -Wait
    if ($d.ExitCode -eq 0){
        $driversCount++
    }
}
#C:\Windows\sysnative\

if ($driverCount -eq $drivers.Count){
    Add-StatusRegistryProperty -Application $appName -Operation $driverOp -Status 0
}

# Check if IDE firewall rule has been added, if not, add it
$existingIDERule = Get-NetFirewallRule -DisplayName $ideRule.DisplayName -ErrorAction SilentlyContinue

if ($existingIDERule){
    $existingIDERule | Remove-NetFirewallRule
}

$ideRule = @{
    DisplayName = "Arduino IDE"
    Description = "Arduino IDE"
    Direction = "Inbound"
    Profile = "Public"
    Program = "C:\program files\arduino-ide\arduino ide.exe"
    Action = "Block"
}

New-NetFirewallRule @ideRule
Add-StatusRegistryProperty -Application $appName -Operation $ideFWOp -Status 0

<#
#Check if mDNS firewall rule has been added, if not, add it
$mDNSRule = @{
    DisplayName = "Arduino mDNS"
    Description = "Arduino mDNS"
    Direction = "Inbound"
    Profile = "Public"
    Program = "$localDir\data\packages\builtin\tools\mdns-discovery\1.0.9\mdns-discovery.exe"
    Action = "Block"
}

$existingmDNSRule = Get-NetFirewallRule -DisplayName $mDNSRule.DisplayName -ErrorAction SilentlyContinue

if ($existingmDNSRule){
    $existingmDNSRule | Remove-NetFirewallRule
}

New-NetFirewallRule @mDNSRule
Add-StatusRegistryProperty -Application $appName -Operation $mdnsFWOp -Status 0
#>

# Add mDNS firewall rule for all users
$mDNSRule = @{
    DisplayName = "Arduino mDNS"
    Description = "Arduino mDNS"
    Direction = "Inbound"
    Profile = "Public"
    Program = "appdata\local\arduino15\packages\builtin\tools\mdns-discovery\1.0.9\mdns-discovery.exe"
    Action = "Block"
}
New-NetFirewallRuleAllUsers @mDNSRule
Add-StatusRegistryProperty -Application $appName -Operation $mdnsFWOp -Status 0

# Copy script to local storage
$scriptDest = "$env:SYSTEMDRIVE\Scripts"
if (!(Test-Path -Path $scriptDest)){
    New-Item -Path $scriptDest -ItemType Directory -Force
}
Copy-Item -Path $script.FullName -Destination $scriptDest -Force
Add-StatusRegistryProperty -Application $appName -Operation $scriptOP -Status 0

# Add scheduled task to launch script on user logon
$taskName = "Arduino mDNS Discovery"
$taskDescription = "Add Arduino mDNS Discovery firewall rule at user logon"
$taskPath = "Intune\Applications"

# Check if a task with a matching name exists, if so, remove it
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue){
    Unregister-ScheduledTask -TaskName $taskName 
}

$actionParams = @{
    Execute = "powershell.exe"
    Argument = "-ExecutionPolicy Bypass -File $scriptDest\$($script.Name)"
}

$settingsParams = @{
    AllowStartIfOnBatteries = $true
    DontStopIfGoingOnBatteries = $true
    ExecutionTimeLimit = (New-TimeSpan -Minutes 5)
}

$principalParams = @{
    UserId = 'SYSTEM'
    RunLevel = 'Highest'
}

$taskParams = @{
    Action = New-ScheduledTaskAction @actionParams
    Principal = New-ScheduledTaskPrincipal @principalParams
    Trigger = New-ScheduledTaskTrigger -AtLogOn
    Settings = New-ScheduledTaskSettingsSet @settingsParams
    TaskName = $taskName
    TaskPath = $taskPath
    Description = $taskDescription
}

Register-ScheduledTask @taskParams -Force
Add-StatusRegistryProperty -Application $appName -Operation $sTaskOp -Status 0