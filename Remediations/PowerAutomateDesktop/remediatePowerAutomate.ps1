$package = "Microsoft.PowerAutomateDesktop"

try {
    Write-Output "Removing $($package)"
    Get-AppxPackage -Name $package -AllUsers | Remove-AppPackage -AllUsers
}
catch {
    Write-Output "Error removing $($package)"
}