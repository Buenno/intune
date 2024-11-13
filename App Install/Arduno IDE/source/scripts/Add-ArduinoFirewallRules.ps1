# Used by Arduino application installation script
# Adds a firewall rule for the mDNS service used by Arduino IDE at user login, if it doesn't already exist

$scheduledTaskName = "Add Arduino Firewall Rules"
$fwDisplayName = "Arduino mDNS - $lastLoggedOnUser"
$programExePath = "appdata\local\arduino15\packages\builtin\tools\mdns-discovery\1.0.9\mdns-discovery.exe"

# Search the Task Scheduler log in the last minute to see who triggered the script, returns the first hit only, then captures the DOMAIN\USERNAME value only.
$eventParams = @{
    logname=”Microsoft-Windows-TaskScheduler/Operational”
    ID=119
    starttime=((Get-Date).AddMinutes(-1))
}

$lastLoggedOnUser = (Get-WinEvent -FilterHashtable $eventParams | Where-Object {$_.Message -match $scheduledtaskname} | Select-Object -First 1 @{N='User';E={$_.Properties[1].Value}} | Select-Object -ExpandProperty User).Split("\")[1]
$existingmDNSRule = Get-NetFirewallRule -DisplayName $fwDisplayName -ErrorAction SilentlyContinue

# Exit if no user is found, or if an existing DNS rule is found
if ((!$lastLoggedOnUser) -or (!$existingmDNSRule))
{
    exit
}

# Add the new firewall rule
$primaryUserFolders = $env:public.Trim("\Public")
$programPath = "$primaryUserFolders\$lastLoggedOnUser\$programExePath"

$mDNSRule = @{
    DisplayName = $fwDisplayName
    Description = "Arduino mDNS"
    Direction = "Inbound"
    Profile = "Public"
    Program = $programPath
    Action = "Block"
}

if (!($existingmDNSRule)){
    New-NetFirewallRule @mDNSRule -Protocol UDP
    New-NetFirewallRule @mDNSRule -Protocol TCP
}
