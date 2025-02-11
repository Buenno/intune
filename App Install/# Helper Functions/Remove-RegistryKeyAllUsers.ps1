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