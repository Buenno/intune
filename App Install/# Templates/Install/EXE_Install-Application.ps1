$ErrorActionPreference = 'Stop'

$appName = ""
$binary = Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.exe
$installer = $binary.FullName
$installOp = "Installation"

$installParams = @(
    "/silent"
)

# Install application
$i = Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Add status registry key
if ($i.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status '0' 
}