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

# Get the uninstall string from registry
$appName =      "Python"
$binary =       Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.exe
$uninstaller =  $binary.FullName

$uninstallParams = @(
    "/uninstall",
    "/quiet"
)

# Uninstall application
$u = Start-Process $uninstaller -ArgumentList "$($uninstallParams -join " ")" -PassThru -Wait

# Remove status registry key
if ($u.ExitCode -eq 0){
    Remove-StatusRegistryKey -Application $appName 
}