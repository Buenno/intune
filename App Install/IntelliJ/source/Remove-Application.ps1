$ErrorActionPreference = 'Stop'

$version =          "2024.2.3"
$appName =          "IntelliJ IDEA Community Edition"
$displayName =      "$appname $version"
$publisher =        "JetBrains s.r.o."
$processName =      "idea64"
$installDir =       $env:ProgramFiles
$appdataDir =       "\AppData\Roaming\JetBrains"
$appdataSubDir =    "IdeaIC2024.2"
$rootUserReg =      "SOFTWARE\JavaSoft"
$statusReg =        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$appName"
$uninstallReg =     "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

function Remove-ItemAllUsers {
    <#
    .SYNOPSIS
    Removes a file/folder from all users.

    .DESCRIPTION
    Removes a file/folder from all user profile folders on the device. Works with Default, AD, and Entra users. 
    
    .PARAMETER Path
    The path to the source file/folder, relative to the user profile path.

    .PARAMETER IncludeDefault
    Removes file/folder from Default user profile.
    
    .OUTPUTS
    None

    .EXAMPLE
    Remove-ItemToAllUsers -Path \MyConfigFiles -IncludeDefault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
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
        # Trim any leading backslash from path string
        $Path = $Path.TrimStart("\")
        foreach ($profile in $profileList){
            # Remove file/folder if it exists
            if (Test-Path "$($profile.ProfilePath)\$Path"){
                Remove-Item -Path "$($profile.ProfilePath)\$Path" -Recurse -Force 
            }
        }
    }
}

function Remove-RegistryKeyAllUsers {
    <#
    .SYNOPSIS
    Deleted the specified registry key - for all users.

    .DESCRIPTION
    The cmdlet deletes a regitry key from all user profiles.

    .PARAMETER Path
    Specifies a path of the registry key being removed, relative to HKEY_USERS.
    
    .PARAMETER IncludeDefault
    Removes registry key from default user profile.
    
    .OUTPUTS
    None

    .EXAMPLE
    Remove-RegistryKeyAllUsers -Path "Registry::HKEY_USERS\SOFTWARE\Chrome\Prefs\" -IncludeDefault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
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
                UserHive = "$env:SystemDrive\Users\public\NTUSER.DAT"
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

            # Remove the key if it exists
            if (Test-Path Registry::HKEY_USERS\$($profile.SID)\$Path){
                Remove-Item -Path Registry::HKEY_USERS\$($profile.SID)\$Path -Recurse -Force
            }
            
            # Unload ntuser.dat        
            if ($profile.SID -in $unloadedHives.SID) {
                [gc]::Collect()
                reg unload HKU\$($profile.SID) | Out-Null
            }
        }
    }
}

# Get the uninstall string from the registry
$uString = Get-Item -Path "$uninstallReg\$displayName" | Get-ItemPropertyValue -Name UninstallString
$uParams = @(
    "/S"
    )

# Stop existing processes
Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue 

# Uninstall application
Start-Process -FilePath "$uString" -ArgumentList "$($uParams -join " ")" -Wait

# Jetbrains apps share EULA and data sharing settings accross their applications, so we can't delete the associated
# config files if another Jetbrains app is installed. 
$installedApps = Get-ChildItem -Path $uninstallReg | Get-ItemProperty | Where-Object {($_.Publisher -eq $publisher) -and ($_.DisplayName -ne $displayName)}
if ($installedApps.Count -ge '1'){
    Remove-ItemAllUsers -Path $appdataDir\$appdataSubDir -IncludeDefault
}
else {
    Remove-ItemAllUsers -Path $appdataDir -IncludeDefault
    Remove-RegistryKeyAllUsers -Path $rootUserReg
}

# Delete install directory
Remove-Item -Path $installDir\$appName -Recurse -Force

# Delete status registry key
Remove-Item -Path $statusReg -Force