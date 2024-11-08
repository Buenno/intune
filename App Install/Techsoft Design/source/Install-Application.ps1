$ErrorActionPreference = 'Stop'

$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$transform = Get-ChildItem -Path "$PSScriptRoot\transform" -Filter *.mst
$licence = Get-ChildItem -Path "$PSScriptRoot\config" -Filter *.lc3
$installDir = "C:\Program Files\TechSoft Design Tools\TechSoft Design V3"
$installer = "msiexec.exe"

$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "TRANSFORMS=""$($transform.FullName)"""
)

# Install application
Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Copy licence file 
$licence | Copy-Item -Destination $installDir -Force
