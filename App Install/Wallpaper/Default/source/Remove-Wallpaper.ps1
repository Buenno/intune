<#
.SYNOPSIS
    Deletes wallpaper files and reverts to default.
#>

$ErrorActionPreference = 'Stop'

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

# Set the download destination for the desktop wallpaper
$dest = "C:\Windows\Web\Wallpaper\Windows"

# Get the desktop wallpaper files
$wallpapers = Get-ChildItem -Path $dest -Filter "wallpaper-*-*.png" 
$wallpapers | Remove-Item -Force

# Set variables for registry key path
$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

# Delete registry key as it's no longer required
Remove-Item -Path $RegKeyPath -Force

# Refresh system to use updated reg keys
RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True

# Remove status registry key
Remove-StatusRegistryKey -Application Wallpaper