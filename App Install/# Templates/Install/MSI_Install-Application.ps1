$ErrorActionPreference = 'Stop'

$appName = ""
$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$transform = Get-ChildItem -Path "$PSScriptRoot\transform" -Filter *.mst
$installer = "msiexec.exe"
$installOp = "Installation"

$installParams = @(
    "/i $($binary.FullName)",
    "/qn",
    "TRANSFORMS=""$($transform.FullName)"""
)

# Install application
$i = Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Add status registry key
if ($i.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status '0' 
}