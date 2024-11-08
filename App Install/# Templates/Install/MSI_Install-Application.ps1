$ErrorActionPreference = 'Stop'

$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$transform = Get-ChildItem -Path "$PSScriptRoot\transform" -Filter *.mst
$installer = "msiexec.exe"

$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "TRANSFORMS=""$($transform.FullName)"""
)

# Install application
Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait