$ErrorActionPreference = 'Stop'

function Test-RegistryValue {
    param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Value
    )
    try {
        Get-ItemProperty -Path $Path -Name $Value -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

## Install Papercut MF Client
$binary = ".\win\pc-client-admin-deploy.msi"
$params = @(
    "/qn",
    "ALLUSERS=1"
)

try {
    $p = Start-Process $binary -ArgumentList $params -PassThru -Wait
}
catch {
    Write-Host "Installation failed. The following error was returned: $($_.Exception.Message)"
}

$goodExitCodes = @("0", "1638")

## Add the autostart registry keys and values
if ($goodExitCodes -contains $p.ExitCode){
    if (!(Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Value "PapercutMFClient")){
        try {
            New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "PaperCutMFClient" -Value "C:\Program Files\PaperCut MF Client\pc-client.exe" | Out-Null
        }
        catch {
            Write-Host "$($_.Exception.Message)"
        }
    }
}