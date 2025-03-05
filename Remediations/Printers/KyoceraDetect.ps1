$drivers = @(
    "Kyocera TASKalfa 8052ci KX",
    "Kyocera TASKalfa 8002i KX",
    "Kyocera TASKalfa 6054ci KX",
    "Kyocera TASKalfa 6052ci KX",
    "Kyocera TASKalfa 4052ci KX",
    "Kyocera TASKalfa 352ci KX",
    "Kyocera TASKalfa 351ci KX",
    "Kyocera TASKalfa 350ci KX",
    "Kyocera TASKalfa 3253ci KX",
    "Kyocera TASKalfa 3252ci KX"
)

$missing = New-Object System.Collections.ArrayList

foreach ($driver in $drivers){
    try {
        Get-PrinterDriver -Name $driver -ErrorAction Stop
    }
    catch {
        $missing.Add($driver) | Out-Null
    }
}

if ($missing -ge 1){
    Write-Host "$($missing.Count) drivers missing - $($missing -join ", ")"
    exit 1
}
else {
    Write-Host "All drivers successfully installed"
    exit 0
}
