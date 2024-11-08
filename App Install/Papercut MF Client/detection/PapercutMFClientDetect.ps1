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

## Get the uninstall string
$application = "Papercut MF Client"
$autorun = "PaperCutMFClient"
$uReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$aReg = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"

$uReg = (Get-ChildItem -Path $uReg | Get-ItemProperty | Where-Object {$_.DisplayName -match $($application)})
$aCheck = Test-RegistryValue -Path $aReg -Value $autorun


if (($uReg) -and ($aCheck)){
    Write-Host "$($application) is installed."
    exit 0
}
else {
    Write-Host "$($application) is not installed."
    exit 1
}