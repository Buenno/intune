$ErrorActionPreference = 'Stop'

## Get the uninstall string
$application = "Python"
$version = "3.12.6"
$uReg = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {($_.DisplayName -match $($application)) -and ($_.DisplayVersion -match $version)})

foreach ($entry in $uReg){
    $uParams = @(
        "/x",
        $entry.PSChildName,
        "/qn"
        )

    ## Uninstall application
    try {
        Start-Process msiexec.exe -ArgumentList "$($uParams -join " ")" -Wait
    }
    catch {
        Write-Host "Uninstall of $($entry.DisplayName) failed. The following error was returned: $($_.Exception.Message)"
        exit $LASTEXITCODE
    }
}