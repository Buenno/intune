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