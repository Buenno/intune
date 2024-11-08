$ErrorActionPreference = 'Stop'

## Get the uninstall string
$application = "Google Drive"
$uReg = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match $($application)})
$uParams = @(
    "--silent",
    "--force_stop"
    )

## Uninstall application
try {
    Start-Process "$($uReg.UninstallString)" -ArgumentList "$($uParams -join " ")" -Wait
}
catch {
    Write-Host "Uninstall failed. The following error was returned: $($_.Exception.Message)"
}

## Delete registry keys
$DriveReg = "HKLM:\SOFTWARE\Policies\Google\DriveFS"

if ($LASTEXITCODE -eq 0){
    try {
        Remove-Item $DriveReg -Force
        Remove-Item $uReg.PSPath -Force
    }
    catch {
        Write-Host "Unable to remove registry - $($_.Exception.Message)"
    }
}
