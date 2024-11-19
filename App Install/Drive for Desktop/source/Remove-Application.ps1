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
$appName = "Google Drive"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -eq $appName}
$configPath =   "HKLM:\SOFTWARE\Policies\Google\DriveFS"

$uninstallParams = @(
    "--silent",
    "--force_stop"
)

# Uninstall application
$u = Start-Process $uninstallReg.UninstallString -ArgumentList $uninstallParams -PassThru -Wait

# Delete configuration
try {
    Remove-Item $configPath -Force
    $configDel = $true
}
catch {
    $configDel = $false
}

# Remove status registry key
if (($u.ExitCode -eq 0) -and ($configDel)){
    Remove-StatusRegistryKey -Application $appName 
}
