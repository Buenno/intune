# Modified version of "Azure AD Device Sync to Active Directory" script by Keith Ng

# Entra app registration details
# Requires Device.Read.All and Group.Read.All permissions (application, not delegated!)
$tenantId = ""
$clientId = ""
$certificate = Get-ChildItem -Path Cert:\CurrentUser\MY | Where-Object {$_.friendlyname -eq "EntraSync"}

# Name of the default group of all AD computer objects generated from sync`
# Similar to the "Domain Computers" group for domain-joined devices
$defaultGroup = "Entra Devices"

# The organisational unit the devices and groups should sync to
# Should be a dedicated OU used by this script only
$deviceOrgUnit = "OU=Devices,OU=Entra,OU=TheAbbeySchool,DC=tas,DC=internal"
$groupOrgUnit = "OU=Groups,OU=Entra,OU=TheAbbeySchool,DC=tas,DC=internal"
$orgUnits = @($deviceOrgUnit, $groupOrgUnit)

# Device/group deletion policies
$removeDeletedDevices = $true # Set to $false if you don't want the script to delete computer objects from AD
$removeDeletedGroups = $true # Set to $false if you don't want the script to delete group objects from AD
$emptyDeviceProtection = $true # Leave as $true (recommended) to prevent the script from deleting computer objects when the device list from Entra is empty (could be due to error)
$emptyGroupProtection = $true # Leave as $true (recommended) to prevent the script from deleting group objects when the group list from Entra is empty (could be due to error)

# Revoke device certificates on deletion from AD - account running this script must have correct permissions
# When $true, will attempt to revoke any certificates (with reason 6 'certificate hold') that have device ID as CN
# Only takes effect when $removeDeletedDevices = $true
$revokeCertOnDelete = $false

# PowerShell module installation check
# If set to $true, will install and update PowerShell modules as necessary
# Setting this value to $false speeds up the script execution time as it skips the checks - but ensure you have the modules installed!
$moduleChecks = $true

#######################################################################################################################################

if ($revokeCertOnDelete) {
    $requiredModules = "ActiveDirectory", "Microsoft.Graph", "Microsoft.Graph.Groups", "Microsoft.Graph.Identity.DirectoryManagement", "PSPKI"
} else {
    $requiredModules = "ActiveDirectory", "Microsoft.Graph", "Microsoft.Graph.Groups", "Microsoft.Graph.Identity.DirectoryManagement"
}
Write-Host "Importing required modules..."
foreach ($module in $requiredModules) {
    if ($moduleChecks) {
        # Check if installed version = online version, if not then update it (reinstall)
        [Version]$onlineVersion = (Find-Module -Name $module -ErrorAction SilentlyContinue).Version
        [Version]$installedVersion = (Get-Module -ListAvailable -Name $module | Sort-Object Version -Descending  | Select-Object Version -First 1).Version
        if ($onlineVersion -gt $installedVersion) {
            Write-Host "Installing module $($module)..."
            Install-Module -Name $Module -Force -AllowClobber
        }
    }
    # Import modules
    if (!(Get-Module -Name $module)) {
        if ($module -eq "Microsoft.Graph") { # Do not need to import this entire monstrosity
            continue
        }
        Write-Host "Importing module $($module)..."
        Import-Module -Name $module -Force	
    }
}

# Check if device and group org units exist
foreach ($orgUnit in $orgUnits){
    if (!(Get-ADOrganizationalUnit -Filter "distinguishedName -eq `"$($orgUnit)`"")) {
        Write-Host "`nThe specified org unit does not exist! Exiting script..." -ForegroundColor Red
        exit(1)
    }
}

Write-Host "`nFetching default group ID..."
try {
    if (($defaultGroupObject = Get-ADGroup -Filter "Name -eq `"$($defaultGroup)`"")) {
        $defaultGroupObject | Move-ADObject -TargetPath $groupOrgUnit # Ensure the default group is in our specified OU
        $defaultGroupId = (Get-ADGroup $defaultGroup -Properties @("primaryGroupToken")).primaryGroupToken
    } else {
        New-ADGroup -Path $groupOrgUnit -Name $defaultGroup -GroupCategory Security -GroupScope Global
        $defaultGroupId = (Get-ADGroup $defaultGroup -Properties @("primaryGroupToken")).primaryGroupToken
    }
} catch {
    Write-Host "`nSomething went wrong while fetching default group ID! Exiting script..." -ForegroundColor Red
    exit(1)
}

# Connect to Microsoft Graph PowerShell
Write-Host "`nConecting to Microsoft Graph..."
try {
    Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $certificate.Thumbprint -NoWelcome
} catch {
    Write-Host "`nSomething went wrong while connecting to MS Graph! Exiting script..." -ForegroundColor Red
    exit(1)
}

try {
    Get-MgDevice | Out-Null
} catch {
    Write-Host "`nCannot fetch devices list from Entra - do you have the correct app permission set? Exiting script..." -ForegroundColor Red
    exit(1)
}

try {
    Get-MgGroup | Out-Null
} catch {
    Write-Host "`nCannot fetch groups list from Entra - do you have the correct app permission set? Exiting script..." -ForegroundColor Red
    exit(1)
}

$entraDevices = @{} # To store device ID and name of all devices synced from Entra to AD
$entraGroups = @{} # To store group ID and name of all groups synced from Entra to AD

# Pull all Entra joined devices
Write-Host "`nFetching all Entra joined devices..."
foreach ($device in Get-MgDevice -Filter "trustType eq 'AzureAD'" -All) {
    $guid = $device.DeviceId
    Write-Host "`nProcessing device $($guid)..."

    if (!($entraDevices.ContainsKey($guid))) {
        #Write-Host "Adding device $($guid) to Entra devices dictionary..."
        $entraDevices.Add($guid, $device.DisplayName)
    }

    $guid -match "^([0-9a-fA-F]{8})(-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-)([0-9a-fA-F]{11})([0-9a-fA-F])$" | Out-Null
    $sAMAccountName = "$($matches[1])"+"$($matches[3])"+"$"

    Write-Host "Adding/updating AD object for $($guid)..."
    try {
        if (($adDevice = Get-ADComputer -Filter "Name -eq `"$($guid)`"" -SearchBase $deviceOrgUnit)) {
            #Write-Host "Updating AD object for $($guid)..."
            $adDevice | Set-ADComputer -Replace @{"dNSHostName"="$($guid)";"servicePrincipalName"="host/$($guid)";"UserPrincipalName"="host/$($guid)";"sAMAccountName"="$($sAMAccountName)";"description"="$($device.DisplayName)"}
        } else {
            #Write-Host "Creating new AD object for $($guid)..."
            $adDevice = New-ADComputer -Name $guid -DNSHostName $guid -ServicePrincipalNames "host/$($guid)" -UserPrincipalName "host/$($guid)" -SAMAccountName $sAMAccountName -Description "$($device.DisplayName)" -Path $deviceOrgUnit -AccountPassword $NULL -PasswordNotRequired $False -PassThru
        }
        Write-Host "Getting AD object for $($guid)..."
        $adDevice = Get-ADComputer -Filter "Name -eq `"$($guid)`"" -SearchBase $deviceOrgUnit
    } catch {
        Write-Host "Something went wrong while adding/updating AD object for $($guid)" -ForegroundColor Red
    }

    Write-Host "Changing AD primary group for $($guid)..."
    try {
        if (!((Get-ADGroupMember -Identity $defaultGroup | Select-Object -ExpandProperty Name) -contains $guid)) {
            Add-ADGroupMember -Identity $defaultGroup -Members $adDevice
        }
        Get-ADComputer $adDevice | Set-ADComputer -Replace @{primaryGroupID=$defaultGroupId}
        if (Get-ADComputer -Identity $adDevice -Properties memberof | Foreach-Object {$_.MemberOf -like "*Domain Computers*"}) {
            Remove-ADGroupMember -Identity "Domain Computers" -Members $adDevice -Confirm:$false
        }
    } catch {
        Write-Host "Something went wrong while changing AD primary group for $($guid)" -ForegroundColor Red
    }

    $groups = @{} # To store group ID and name of all groups this device belongs to in Entra
    # Fetch all groups this device belongs to, then add it to the group
    Write-Host "Fetching all groups for device $($guid)..."
    foreach ($group in Get-MgDeviceMemberOf -DeviceId $device.Id) { # Note $device.Id != $device.DeviceId, $device.Id is the device's object ID
        $groupId = $group.Id
        $groupName = (Get-MgGroup -GroupId $group.Id).DisplayName

        if (!($entraGroups.ContainsKey($groupId))) {
            #Write-Host "Adding group $($groupId) to Entra groups dictionary..."
            $entraGroups.Add($groupId, (Get-MgGroup -GroupId $groupId).DisplayName)
        }
        if (!($groups.ContainsKey($groupId))) {
            #Write-Host "Adding group $($groupId) to groups dictionary for device $($guid)..."
            $groups.Add($groupId, (Get-MgGroup -GroupId $groupId).DisplayName)
        }

        # Create group if doesn't exist already
        Write-Host "Checking if group $($groupId) exists..."
        if (!($adGroup = Get-ADGroup -Filter "Name -eq `"$($groupId)`"" -SearchBase $groupOrgUnit)) {
            Write-Host "Creating group $($groupId) as it doesnt exist..."
            try {
                $adGroup = New-ADGroup -Path $groupOrgUnit -Name $groupId -Description $groupName -GroupCategory Security -GroupScope Global
            } catch {
                Write-Host "Something went wrong while creating group $($groupId)" -ForegroundColor Red
            }
        }

        try {
            $adGroup = Get-ADGroup -Filter "Name -eq `"$($groupId)`"" -SearchBase $groupOrgUnit
            if (!(($adGroup | Get-ADGroupMember | Select-Object -ExpandProperty Name) -contains $guid)) {
                Write-Host "Adding device $($guid) to group $($groupId)..."
                $adGroup | Add-ADGroupMember -Members $adDevice
            }
        } catch {
            Write-Host "Something went wrong while adding device $($guid) to group $($groupId)" -ForegroundColor Red
        }
    }

    # Remove the device from any AD groups that it should no longer be in
    Write-Host "Removing device $($guid) from any existing AD groups it should no longer be part of..."
    foreach ($group in (Get-ADPrincipalGroupMembership -Identity $adDevice)) {
        if ($group.Name -eq $defaultGroup) { # Don't remove device from its primary default group
            continue
        }
        if (!($group.Name -match "^([0-9a-fA-F]{8})(-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-)([0-9a-fA-F]{11})([0-9a-fA-F])$")) { # Don't remove device from non-Entra groups
            continue
        }
        if (!($groups.ContainsKey($group.Name))) {
            Write-Host "Removing device $($guid) from group $($group.Name)..."
            try {
                $group | Remove-ADGroupMember -Members $adDevice -Confirm:$false
            } catch {
                Write-Host "Something went wrong while removing device $($guid) from group $($group.Name)" -ForegroundColor Red
            }
        }
    }
}

# Remove AD objects that don't exist in Entra anymore
# Checks and redundancies because we want to be as sure as possible before deleting

if (($entraDevices.Count -gt 0) -or (!$emptyDeviceProtection)) {
    Write-Host "`nRemoving deleted devices in Entra from AD..."
    $adDevices = Get-ADComputer -Filter * -SearchBase $deviceOrgUnit | Where-Object Name -match "^([0-9a-fA-F]{8})(-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-)([0-9a-fA-F]{11})([0-9a-fA-F])$"
    foreach ($device in $adDevices) {
        # Delete the AD device if it doesn't exist in Entra
        if (!($entraDevices.ContainsKey($device.Name)) -and !(Get-MgDevice -DeviceId $device.Name -ErrorAction SilentlyContinue)) {
            Write-Host "Removing device $($device.Name)..."
            try {
                if ($removeDeletedDevices) {
                    $device | Remove-ADComputer -Confirm:$false
                    if ($revokeCertOnDelete) {
                        # Revoke certificates where CN = device ID across all certification authorities
                        # Using reason 6 (hold) to allow undo if necessary
                        try {
                            foreach ($certAuthority in (Get-CertificationAuthority).ComputerName) {
                                foreach ($cert in (Get-IssuedRequest -CertificationAuthority $certAuthority -Property SerialNumber -Filter "CommonName -eq $($device.Name)")) {
                                    Write-Host "Revoking certificate $($cert.SerialNumber) for device $($device.Name)..."
                                    $cert | Revoke-Certificate -Reason "Hold"
                                }
                            }
                        } catch {
                            Write-Host "Something went wrong while revoking certificates for device $($device.Name)" -ForegroundColor Red
                        }
                    }
                } else {
                    Write-Host "Device $($device.Name) has not been removed from AD due to device deletion policy in script" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Something went wrong while removing device $($device.Name)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "`nSkipping AD device object deletion as Entra devices list is empty and protection policy is enabled in script" -ForegroundColor Yellow
}

if (($entraGroups.Count -gt 0) -or (!$emptyGroupProtection)) {
    Write-Host "`nRemoving deleted groups in Entra from AD..."
    $adGroups = Get-ADGroup -Filter * -SearchBase $groupOrgUnit | Where-Object Name -match "^([0-9a-fA-F]{8})(-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-)([0-9a-fA-F]{11})([0-9a-fA-F])$"
    foreach ($group in $adGroups) {
        # Delete the AD group if it doesn't exist in Entra
        if (!($entraGroups.ContainsKey($group.Name)) -and !(Get-MgGroup -GroupId $group.Name -ErrorAction SilentlyContinue)) {
            Write-Host "Removing group $($group.Name)..."
            try {
                if ($removeDeletedGroups) {
                    $group | Remove-ADGroup -Confirm:$false
                } else {
                    Write-Host "Group $($group.Name) has not been removed from AD due to group deletion policy in script" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Something went wrong while removing group $($group.Name)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "`nSkipping AD group object deletion as Entra group list is empty and protection policy is enabled in script" -ForegroundColor Yellow
}

Write-Host "`nSync completed!"