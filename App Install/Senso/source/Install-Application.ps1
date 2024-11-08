$ErrorActionPreference = 'Stop'

$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$installer = "msiexec.exe"

$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "LIC=",
    "SITE="
)

# Install application
Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait