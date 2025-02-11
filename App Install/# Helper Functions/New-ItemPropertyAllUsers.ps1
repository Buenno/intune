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