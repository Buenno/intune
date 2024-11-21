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

$appName = "Papercut MF"
$installer = "msiexec.exe"
$autoRunKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run\PapercutMFClient"

# Get uninstall string from registry
$uninstallReg = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object {$_.DisplayName -like "$appName*"}

$uninstallParams = @(
    "/x",
    $uninstallReg.PSChildName,
    "/qn"
)

# Uninstall application
$u = Start-Process $installer -ArgumentList "$($uninstallParams -join " ")" -PassThru -Wait

# Remove status registry key
if ($u.ExitCode -eq 0){
    # Remove autostart registry key
    Remove-Item -Path $autoRunKey -Force -ErrorAction SilentlyContinue
    Remove-StatusRegistryKey -Application $appName 
}