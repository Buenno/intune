$ErrorActionPreference = 'Stop'

$appName = "VC Redis 2015 - 14.0.24215"
$binaryDir = "$env:programdata\Package Cache\{d992c12e-cab2-426f-bde3-fb8c53950b0d}"
$binary = Get-ChildItem -Path $binaryDir -Filter *.exe
$uninstaller = $binary.FullName

$installParams = @(
    "/uninstall",
    "/quiet",
    "/noreboot"
)

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

# Uninstall application
$u = Start-Process $uninstaller -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Add status registry key
if ($u.ExitCode -eq 0){
    Remove-StatusRegistryKey -Application $appName 
}