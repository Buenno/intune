$ErrorActionPreference = 'Stop'

function Add-StatusRegistryProperty {
    <#
    .SYNOPSIS
    Adds an application status value to the registry.

    .DESCRIPTION
    Adds an application installation status value to the registry based on the supplied parameters, creates a parent key using the application name if required.
    
    .PARAMETER Application
    The name of the application. 

    .PARAMETER Operation
    The name of the operation your would like to add the status for.

    .PARAMETER Status
    The status of the operation. Valid values are "0" = Failed, and "1" = Success.
    
    .OUTPUTS
    None

    .EXAMPLE
    Add-StatusRegistryProperty -Application "Google Chrome" -Operating "Application Configuration" -Status "1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Application,
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        [Parameter(Mandatory = $true)]
        [ValidateSet("0","1")]
        [string]$Status
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        $statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$Application"
        # Create status registry key if it doesn't exist
        if (!(Test-Path $statusReg)){
            New-Item -Path $statusReg -Force | Out-Null
        }
    }
    PROCESS {
        # Add status value to registry  
        New-ItemProperty -Path $statusReg -Name $Operation -Value $Status -PropertyType String -Force | Out-Null
    }
}

function Remove-StatusRegistryKey {
    <#
    .SYNOPSIS
    Removes an application status key from the registry.

    .DESCRIPTION
    Removes an application installation status key from the registry based on the supplied application name.

    .PARAMETER Application
    The name of the application as listed in the registry.
    
    .OUTPUTS
    None

    .EXAMPLE
    Remove-StatusRegistryKey -Application "Google Chrome"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Application
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }
    PROCESS {
        $statusReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Intune_Win32\$Application"
        if ((Test-Path $statusReg)){
            Remove-Item -Path $statusReg -Recurse -Force
        }
    }
} 

$appName =      "Creative Cloud"
$binary =       Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.msi
$installer =    "msiexec.exe"

$installOp =    "Installation"
$autoOp =       "Autostart Disabled"

$installParams = @(
    "/i $($binary.FullName)",
    "/qn"
)

# Remove existing status registry key
Remove-StatusRegistryKey -Application $appName

# Install application
$i = Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Add status registry key
if ($i.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status '0' 

    # Disable autorun
    $autorunKey =       "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
    $disabledValue =    "03000000F6538EAD313BDB01"
    
    $autorunProps = @(
        "Adobe CCXProcess",
        "Adobe Creative Cloud"
    )

    # Create the startup key if it doesn't exist
    if (!(Test-Path -Path $autorunKey)){
        New-Item -Path $autorunKey -Force
    }

    foreach ($prop in $autorunProps){
        # Covert the $disabledValue to binary as required by the property type and update
        New-ItemProperty -Path $autorunKey -Name $prop -Value ([byte[]] -split ($disabledValue -replace '..', '0x$& ')) -PropertyType Binary -Force
    }
    Add-StatusRegistryProperty -Application $appName -Operation $autoOp -Status '0'
}

