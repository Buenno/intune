$ErrorActionPreference = 'Stop'

## Get the uninstall string
$application = "7-Zip"
$version = "24.08"
$uReg = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {($_.DisplayName -match $($application)) -and ($_.DisplayVersion -eq $version)})
$uParams = @(
    "/S"
    )

## Uninstall application
try {
    Start-Process $uReg.UninstallString -ArgumentList "$($uParams -join " ")" -Wait
}
catch {
    Write-Host "Uninstall failed. The following error was returned: $($_.Exception.Message)"
}

exit $LASTEXITCODE