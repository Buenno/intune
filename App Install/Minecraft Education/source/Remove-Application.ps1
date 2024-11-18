$ErrorActionPreference = 'Stop'

# Get uninstall string from registry 
$installer = "msiexec.exe"
$appName = "Minecraft Education"
$uninstallReg = Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {($_.DisplayName -eq $appName) -and ($_.PSChildName -like "{*}")}

$uninstallParams = @(
    "/x",
    $uninstallReg.PSChildName,
    "/qn"
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
$u = Start-Process $installer -ArgumentList "$($uninstallParams -join " ")" -PassThru -Wait
if ($u.ExitCode -eq 0){
    Remove-StatusRegistryKey -Application $appName 
}