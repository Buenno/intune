$ErrorActionPreference = 'Stop'

## Get the uninstall string
$application = "Python"
$version = "3.12.6"
$uReg64 = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {($_.DisplayName -match $($application)) -and ($_.DisplayVersion -match $version)})
$uReg32 = (Get-ChildItem -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {($_.DisplayName -match $($application)) -and ($_.DisplayVersion -match $version)})


if (($uReg64.count -eq 9) -and (@($uReg32).count -eq 1)){
    Write-Host "$application is installed."
    exit 0
}
else {
    Write-Host "$application is not installed."
    exit 1
}