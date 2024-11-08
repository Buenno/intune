$package = "Microsoft.PowerAutomateDesktop"
$appxPackage = Get-AppxPackage -Name $package -AllUsers

if ($appxPackage){
    Write-Output "$($package) is installed"
    exit 1
}
else {
    Write-Output "$($package) is not installed"
    exit 0
}