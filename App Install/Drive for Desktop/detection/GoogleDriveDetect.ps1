$ErrorActionPreference = 'Stop'

## Get the uninstall string
$application = "Google Drive"
$uReg = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match $($application)})
$DriveReg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\DriveFS").psobject.properties.name -contains "AbbeyConfigInstalled" 

if (($uReg) -and ($DriveReg)){
    Write-Host "$($application) is installed."
    exit 0
}
else {
    Write-Host "$($application) is not installed."
    exit 1
}
