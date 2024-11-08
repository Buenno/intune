$ErrorActionPreference = 'Stop'

$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$transform = Get-ChildItem -Path "$PSScriptRoot\transform" -Filter *.mst
$config = Get-ChildItem -Path "$PSScriptRoot\config"
$configDest = "C:\ProgramData\SafeExamBrowser\"
$installer = "msiexec.exe"

$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "TRANSFORMS=""$($transform.FullName)"""
)

# Install application
Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Copy config
if (!(Test-Path $configDest)){
    New-Item -ItemType Directory -Path $configDest -Force
}
$config | Copy-Item -Destination $configDest -Force