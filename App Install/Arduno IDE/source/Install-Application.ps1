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

$appName =      "Arduino"
$binary =       Get-ChildItem -Path "$PSScriptRoot\binary" -Filter *.exe
$certificates = Get-ChildItem -Path "$PSScriptRoot\certificates" -Filter *.cer
$installer =    $binary.FullName

$installOp =    "Installation"
$certsOp =      "Trusted Publisher Certificates Installed"
$ideFWOp =      "Added Java firewall rule"
$lnkOp =        "Desktop shortcut removed"

# Remove existing status registry key
Remove-StatusRegistryKey -Application $appName

# Install the various trusted publisher certificates
$certStorePath = 'Cert:\LocalMachine\TrustedPublisher'
foreach ($cert in $certificates){
    $certParams = @{
        FilePath = $cert.FullName
        CertStoreLocation = $certStorePath
    }
    try {
        Import-Certificate @certParams
    }
    catch [System.UnauthorizedAccessException] {
		$CertStore = Get-Item $certStorePath
		$CertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadWrite")
		$CertStore.Add($cert.FullName)
		$CertStore.Close()
    }
    catch {
        Write-Error $_
        break
    }
}

Add-StatusRegistryProperty -Application $appName -Operation $certsOp -Status '0'

# Install application
$installParams = @(
    "/S",
    "/NCRC"
)

$i = Start-Process $installer -ArgumentList "$($installParams -join " ")" -PassThru -Wait

# Add status registry key
if ($i.ExitCode -eq 0){
    Add-StatusRegistryProperty -Application $appName -Operation $installOp -Status '0' 
}

# Add firewall rule for Java to suppress user prompt 
$jreRule = @{
    DisplayName = "Arduino IDE - Java"
    Description = "Arduino IDE - Java"
    Direction = "Inbound"
    Profile = "Public"
    Program = "${env:ProgramFiles(x86)}\arduino\java\bin\javaw.exe"
    Action = "Block"
}

$existingJRERule = Get-NetFirewallRule -DisplayName $jreRule.DisplayName -ErrorAction SilentlyContinue

if ($existingJRERule){
    $existingJRERule | Remove-NetFirewallRule
}

New-NetFirewallRule @jreRule
Add-StatusRegistryProperty -Application $appName -Operation $ideFWOp -Status '0'

# Arduino write bad installers, so we need to remove the desktop shortcut
Remove-Item -Path "$env:PUBLIC\Desktop\Arduino.lnk" -Force
Add-StatusRegistryProperty -Application $appName -Operation $lnkOp -Status '0'