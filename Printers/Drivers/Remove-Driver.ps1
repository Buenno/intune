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

# Remove required drivers
foreach ($driver in $drivers){
    Remove-PrinterDriver -name $driver
}

# Uninstall driver package
C:\Windows\sysnative\pnputil.exe /delete-driver ".\Kyocera\oemsetup.inf_amd64_9359bc628c627b7a\oemsetup.inf" /uninstall

