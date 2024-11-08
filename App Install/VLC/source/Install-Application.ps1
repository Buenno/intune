$ErrorActionPreference = 'Stop'

$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$installer = "msiexec.exe"

$installParams = @(
    "/i $($binary.FullName)",
    "/qn"
)

# Install application
Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait