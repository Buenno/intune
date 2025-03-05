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

# Install driver package
C:\Windows\sysnative\pnputil.exe /add-driver ".\Kyocera\oemsetup.inf_amd64_9359bc628c627b7a\oemsetup.inf" /install

# Add required drivers from package
foreach ($driver in $drivers){
    Add-PrinterDriver -name $driver
}
