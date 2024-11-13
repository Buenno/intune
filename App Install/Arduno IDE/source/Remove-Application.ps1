$ErrorActionPreference = 'Stop'

## Get the uninstall string
$application = "Arduino IDE"
$reg = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object {$_.DisplayName -match $($application)})

foreach ($entry in $reg){
    $params = @(
        "/x",
        $entry.PSChildName,
        "/qn"
        )

    ## Uninstall application
    try {
        Start-Process msiexec.exe -ArgumentList "$($params -join " ")" -Wait
    }
    catch {
        Write-Host "Uninstall of $($entry.DisplayName) failed. The following error was returned: $($_.Exception.Message)"
        exit $LASTEXITCODE
    }
}