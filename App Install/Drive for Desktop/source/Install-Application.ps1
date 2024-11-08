$ErrorActionPreference = 'Stop'
$DriveReg = "HKLM:\SOFTWARE\Policies\Google\DriveFS"

## Install Google Drive for Desktop

$iString = ".\GoogleDriveSetup.exe"
$iParams = @(
    "--silent",
    "--gsuite_shortcuts=false"
)

try {
    $p = Start-Process $iString -ArgumentList "$($iParams -join " ")" -PassThru -Wait
}
catch {
    Write-Host "Installation failed. The following error was returned: $($_)"
}

$goodExitCodes = @("0", "1638")

## Add the configuration registry keys and values
if ($goodExitCodes -contains $p.ExitCode){
    if (!(Test-Path $DriveReg)){
        try {
            New-Item $DriveReg -Force
        }
        catch {
            Write-Host "$($_)"
        }
    }
    try {
        if (!((Get-ItemProperty -Path $DriveReg).psobject.properties.name -contains "AbbeyConfigInstalled")){
            ## Config missing - create it
            New-ItemProperty -Path $DriveReg -Name "ContentCachePath" -Value "%LOCALAPPDATA%\Google\DriveFS" -PropertyType String -Force
            New-ItemProperty -Path $DriveReg -Name "AutoStartOnLogin" -Value "1" -PropertyType DWord -Force
            New-ItemProperty -Path $DriveReg -Name "DefaultMountPoint" -Value "G" -PropertyType String -Force
            New-ItemProperty -Path $DriveReg -Name "DirectConnection" -Value "1" -PropertyType DWord -Force
            New-ItemProperty -Path $DriveReg -Name "AbbeyConfigInstalled" -PropertyType DWord -Force
        } 
    }
    catch {
        Write-Host "Failed creating registry keys. Error: $($_)"
    }
}