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

$appName =      "Arduino IDE"
$installer =    "msiexec.exe"

# source files
$binary =       Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$transform =    Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.mst
$script =       Get-ChildItem -Path "$PSScriptRoot\scripts" -Filter *.ps1
$certificates = Get-ChildItem -Path "$PSScriptRoot\config\certificates" -Filter *.cer

$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "ALLUSERS=1",
    "TRANSFORMS=$($transform.FullName)"
)

# Operations to log in the registry
$installOp =    "Installation"
$certsOp =      "Certificates Installed"
$ideFWOp =      "IDE Firewall rules Created"   
$mdnsFWOp =     "mDNS Firewall rules Created"
$scriptOP -     "Script Copied to Local Storage"
$sTaskOp =      "Scheduled Task Created"

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
$i = Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait
if ($i.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status 0
}

# Check if IDE firewall rule has been added, if not, add it
$ideRule = @{
    DisplayName = "Arduino IDE"
    Description = "Arduino IDE"
    Direction = "Inbound"
    Profile = "Public"
    Program = "C:\program files\arduino-ide\arduino ide.exe"
    Action = "Block"
}

$existingIDERule = Get-NetFirewallRule -DisplayName $ideRule.DisplayName -ErrorAction SilentlyContinue

if ($existingIDERule){
    $existingIDERule | Remove-NetFirewallRule
}

New-NetFirewallRule @ideRule -Protocol UDP
New-NetFirewallRule @ideRule -Protocol TCP
Add-StatusRegistryProperty -Application $appName -Operation $ideFWOp -Status 0

# Add mDNS firewall rule for all users
$mDNSRule = @{
    DisplayName = "Arduino mDNS"
    Description = "Arduino mDNS"
    Direction = "Inbound"
    Profile = "Public"
    Program = "appdata\local\arduino15\packages\builtin\tools\mdns-discovery\1.0.9\mdns-discovery.exe"
    Action = "Block"
}
New-NetFirewallRuleAllUsers @mDNSRule -Protocol UDP
New-NetFirewallRuleAllUsers @mDNSRule -Protocol TCP
Add-StatusRegistryProperty -Application $appName -Operation $mdnsFWOp -Status 0

# Copy script to local storage
$scriptDest = "$env:SYSTEMDRIVE\Scripts"
if (!(Test-Path -Path $scriptDest)){
    New-Item -Path $scriptDest -ItemType Directory -Force
}
Copy-Item -Path $script.FullName -Destination $scriptDest -Force

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
    Argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $($script.FullName)"
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