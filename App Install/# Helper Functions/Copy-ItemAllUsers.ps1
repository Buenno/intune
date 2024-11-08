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