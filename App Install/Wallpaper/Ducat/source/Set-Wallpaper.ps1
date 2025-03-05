<#
.SYNOPSIS
    Download a screen ratio optimized wallpaper and apply it to the desktop.
.DESCRIPTION
    The script determines the screen ratio of the primary monitor and downloads a wallpaper for this ratio 
    from a blob storage address. In certain cases the ratio has a fallback if a wallpaper with the detected 
    ratio is not found.

    This is configured as an Intune script in order for it to run during ESP, it will then be overwritten by a configuration policy.
.NOTES
    Modified Oliver Kieselbach's wallpaper script to suit
    https://github.com/okieselbach/Intune/blob/master/Set-Wallpaper.ps1
#>

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

function Get-Divisors($n) {
    $div = @()

    foreach ($i in 1..($n/3)) {
        $d = $n/$i
        if (($d -eq [System.Math]::Floor($d)) -and -not ($div -contains $i)) {
            $div += $i
            $div += $d
        }
    }
    $div | Sort-Object
}

function Get-CommonDivisors($x, $y) {
    $xd = Get-Divisors $x
    $yd = Get-Divisors $y
    $div = @()

    foreach ($i in $xd) { 
        if ($yd -contains $i) { 
            $div += $i 
        } 
    }
    $div | Sort-Object
}

function Get-GreatestCommonDivisor($x, $y) {
    $d = Get-CommonDivisors $x $y
    $d[$d.Length-1]
}

function Get-Ratio($x, $y) {
    $d = Get-GreatestCommonDivisor $x $y

    New-Object PSObject -Property @{
        X = $x
        Y = $y
        Divisor = $d
        XRatio = $x/$d
        YRatio = $y/$d
        Ratio = "$($x/$d):$($y/$d)"
    };
}

# Set the wallpaper format (default, house)
$wpFormat = "ducat"
Add-StatusRegistryProperty -Application Wallpaper -Operation "Wallpaper format - $wpFormat" -Status 0
# Set the base URL of where the wallpapers are stored
$baseURL = ""
# Set the download destination for the desktop wallpaper
$dest = "C:\Windows\Web\Wallpaper\Windows"

# Find the display ratio
Add-Type -AssemblyName System.Windows.Forms

$x = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Width
$y = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize.Height

$ratio = Get-Ratio $x $y

# Set the desktop wallpaper file name and paths
$filenameRatio = $ratio.Ratio -replace (":", "x")
$dFileFormat = "wallpaper-$filenameRatio-$wpFormat.png"
$lFileFormat = "wallpaper-$filenameRatio-default.png"
$dImageURL = "$baseURL/$dFileFormat"
$lImageURL = "$baseURL/$lFileFormat"
$dImagePath = "$dest\$dFileFormat"
$lImagePath = "$dest\$lFileFormat"

# Download desktop wallpaper
Invoke-WebRequest -Uri $dImageURL -OutFile $dImagePath -TimeoutSec 10 
Add-StatusRegistryProperty -Application Wallpaper -Operation "Desktop Wallpaper DL" -Status 0
# Download lockscreen wallpaper
Invoke-WebRequest -Uri $lImageURL -OutFile $lImagePath -TimeoutSec 10
Add-StatusRegistryProperty -Application Wallpaper -Operation "Lockscreen Wallpaper DL" -Status 0

# Set variables for registry key path and names of registry values to be modified
$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$StatusValue = "1"

# Check whether registry key path exists, create it if it does not
if(!(Test-Path $RegKeyPath)){
    New-Item -Path $RegKeyPath -Force
}
if (Test-Path -Path $lImagePath){
    New-ItemProperty -Path $RegKeyPath -Name "LockScreenImageStatus" -Value $StatusValue -PropertyType DWORD -Force
    New-ItemProperty -Path $RegKeyPath -Name "LockScreenImagePath" -Value $lImagePath -PropertyType STRING -Force
    New-ItemProperty -Path $RegKeyPath -Name "LockScreenImageUrl" -Value $lImagePath -PropertyType STRING -Force
    Add-StatusRegistryProperty -Application Wallpaper -Operation "Lockscreen CSP Set" -Status 0
}
if (Test-Path -Path $dImagePath){
    New-ItemProperty -Path $RegKeyPath -Name "DesktopImageStatus" -Value $StatusValue -PropertyType DWORD -Force
    New-ItemProperty -Path $RegKeyPath -Name "DesktopImagePath" -Value $dImagePath -PropertyType STRING -Force
    New-ItemProperty -Path $RegKeyPath -Name "DesktopImageUrl" -Value $dImagePath -PropertyType STRING -Force
    Add-StatusRegistryProperty -Application Wallpaper -Operation "Desktop CSP Set" -Status 0
}

RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True
Add-StatusRegistryProperty -Application Wallpaper -Operation "Refresh Executed" -Status 0