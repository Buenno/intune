$ErrorActionPreference = 'Stop'

$installer = "msiexec.exe"
$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$transform = Get-ChildItem -Path "$PSScriptRoot\transform" -Filter *.mst

$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "TRANSFORMS=""$($transform.FullName)"""
)

Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait