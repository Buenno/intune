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

$appName =      "Audacity"
$binary =       Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.exe
$config =       Get-ChildItem -Path "$PSScriptRoot\config" -Filter *.cfg
$configPath =   "\AppData\Roaming\audacity"
$installer =    $binary.FullName

$installOp =    "Installation"
$configOp =     "Configuration File Copied"

$installParams = @(
    "/SP-",
    "/VERYSILENT",
    "/SUPPRESSMSGBOXES",
    "/MERGETASKS=""!desktopicon"""
)

# Remove existing status registry key
Remove-StatusRegistryKey -Application $appName 

# Install application
$i = Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Add status registry key
if ($i.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status '0' 
}

# Copy the default configuraiton file to all users inc default
Copy-ItemAllUsers -Path $config.FullName -Destination $configPath -IncludeDefault
Add-StatusRegistryProperty -Application $appName -Operation $configOp -Status '0'