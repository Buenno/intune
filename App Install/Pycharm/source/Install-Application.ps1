$ErrorActionPreference = 'Stop'

# Application details
$appName =          "PyCharm Community Edition"
$installDir =       "$env:ProgramFiles\$appName"
$appdataDir =       "\AppData\Roaming\JetBrains"
$appdataSubDir =    "PyCharmCE2024.3"

$startMenuDir =     "JetBrains"
$startMenuPath =    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
$startMenuFPath =   Join-Path -Path $startMenuPath -ChildPath $startMenuDir

# Source files
$binary =                   Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.exe
$configFile =               Get-ChildItem -Path "$PSScriptRoot\config" -Filter *.config
$platformPropertiesFile =   Get-ChildItem -Path "$PSScriptRoot\config" -Filter *.properties
$shareDenyFile =            Get-ChildItem -Path "$PSScriptRoot\config" -Filter "accepted"
$optionsConfigFile =        Get-ChildItem -Path "$PSScriptRoot\config" -Filter *.xml
$plugins =                  Get-ChildItem -Path "$PSScriptRoot\plugins\"

$installParams = @(
    "/S",
    "/NCRC",
    "/CONFIG=$($configFile.FullName)",
    "/D=$installDir"
    )

# Operations to log in the registry
$installOp =            "Installation"
$platformPropertiesOp = "Platform Properties"
$pluginsOp =            "Plugins"
$eulaOp =               "EULA"
$shareDenyOp =          "Deny Data Sharing"
$optionsOp =            "Options"
$startMenuOp =          "Start Menu Tidied"

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

function New-ItemPropertyAllUsers {
    <#
    .SYNOPSIS
    Creates a new property for a specific item and sets it value - for all users.

    .DESCRIPTION
    Creates a new property for a specific item and sets it value. All user hives will be loaded and targeted. Can also target the default user hive. 
    
    .PARAMETER Path
    The path of the registry key to add the new property to. Will be created if it doesn't exist. 

    .PARAMETER Name
    The name of the new property.

    .PARAMETER Value
    The value of the new property.

    .PARAMETER PropertyType
    Specifies the type of property that is added. The acceptable values for this parameter are:
    
    Binary: Specifies binary data in any form. Used for REG_BINARY values.
    
    DWord: Specifies a 32-bit binary number. Used for REG_DWORD values.

    String: Specifies a null-terminated string. Used for REG_SZ values.
    
    MultiString: Specifies an array of null-terminated strings terminated by two null characters. Used for REG_MULTI_SZ values.
    
    Qword: Specifies a 64-bit binary number. Used for REG_QWORD values.

    .PARAMETER IncludeDefault
    Adds property and value to the default user hive.
    
    .OUTPUTS
    None

    .EXAMPLE
    New-ItemPropertyAllUsers -Path "SOFTWARE\Chrome\Prefs\" -Name AutoUpdate -Value "0" -IncludeDefault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Binary","DWord", "String", "MultiString", "Qword")]
        [string]$PropertyType,
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
                UserHive = "$($profile.ProfileImagePath)\ntuser.dat"
            }
            $profileList.Add($user) | Out-Null
        }

        # Add the default user 
        if ($IncludeDefault){
            $defaultUser = [pscustomobject]@{
                SID = "defaultuser"
                UserHive = "$env:SystemDrive\Users\default\NTUSER.DAT"
            }
            $profileList.Add($defaultUser) | Out-Null
        }
        # Get all user SIDs found in HKEY_USERS (ntuser.dat files that are loaded)
        $loadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object {$_.PSChildname -match $sidRegex} | Select-Object @{name="SID";expression={$_.PSChildName}}

        # Get all users that are not currently logged in (ntuser.dat not loaded)
        $unloadedHives = Compare-Object $profileList.SID $loadedHives.SID | Select-Object @{name="SID";expression={$_.InputObject}}, UserHive
    }
    PROCESS {
        foreach ($profile in $profileList){
            # Trim any leading backslash from path string
            $Path = $Path.TrimStart("\")

            # Load the hive if not already loaded
            if ($profile.SID -in $unloadedHives.SID) {
                reg load HKU\$($profile.SID) $($profile.UserHive) | Out-Null
            } 

            # Create destination registry key if required, then add the property and value
            if (!(Test-Path Registry::HKEY_USERS\$($profile.SID)\$Path)){
                New-Item -Path Registry::HKEY_USERS\$($profile.SID)\$Path -Force | Out-Null
            }
            New-ItemProperty -Path Registry::HKEY_USERS\$($profile.SID)\$Path -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
            
            # Unload ntuser.dat        
            if ($profile.SID -in $unloadedHives.SID) {
                [gc]::Collect()
                reg unload HKU\$($profile.SID) | Out-Null
            }
        }
    }
}

# Delete any existing registry status keys
Remove-StatusRegistryKey -Application $appName

# Install binary
$i = Start-Process $binary.FullName -ArgumentList "$($installParams -join " ")" -PassThru -Wait
if ($i.ExitCode -eq "0"){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status '0'
}

# Copy platform properties file
Copy-Item -Path $platformPropertiesFile.FullName -Destination "$installDir\bin\" -Force
Add-StatusRegistryProperty -Application $appName -Operation $platformPropertiesOp -Status '0'

# Copy plugins
Copy-Item -Path $plugins.FullName -Destination "$installDir\plugins\" -Recurse -Force
Add-StatusRegistryProperty -Application $appName -Operation $pluginsOp -Status '0'

# Copy deny share settings file to all users inc. default
Copy-ItemAllUsers -Path $shareDenyFile.FullName -Destination "$appdataDir\consentOptions\" -IncludeDefault
Add-StatusRegistryProperty -Application $appName -Operation $shareDenyOp -Status '0'

# Copy options file to all users inc. default
Copy-ItemAllUsers -Path $optionsConfigFile.FullName -Destination "$appdataDir\$appdataSubDir\options" -IncludeDefault
Add-StatusRegistryProperty -Application $appName -Operation $optionsOp -Status '0'

# Copy EULA accept to each user registry hive
New-ItemPropertyAllUsers -Path "SOFTWARE\JavaSoft\Prefs\jetbrains\privacy_policy\" -Name "euacommunity_accepted_version" -Value "1.0" -PropertyType String -IncludeDefault
Add-StatusRegistryProperty -Application $appName -Operation $eulaOp -Status '0'    

# Tidy up the start menu
$lnk = Get-ChildItem -Path $startMenuFPath -Filter "$appName*"
Move-Item -Path $lnk.FullName -Destination $startMenuPath -Force
if ((Get-ChildItem -Path $startMenuFPath -ErrorAction SilentlyContinue).count -eq 0){
    Remove-Item -Path $startMenuFPath -Force
}
Add-StatusRegistryProperty -Application $appName -Operation $startMenuOp -Status '0'