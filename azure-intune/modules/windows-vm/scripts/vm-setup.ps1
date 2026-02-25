<#
.SYNOPSIS
    VM Setup Script - Installs vulnerable software baseline and cnspec agent
.DESCRIPTION
    Reads configuration from C:\setup-config.json and installs:
    - Vulnerable software from Azure blob storage
    - Mondoo cnspec agent for security scanning
    - Configures RDP for Azure AD login
    - Triggers Intune MDM enrollment
#>

$ErrorActionPreference = 'Continue'

# Create log file
$logFile = 'C:\setup-log.txt'
Start-Transcript -Path $logFile -Append

Write-Host '=== Starting VM Setup ==='
Write-Host "Timestamp: $(Get-Date)"

# Read configuration from JSON file
$configPath = 'C:\setup-config.json'
if (-not (Test-Path $configPath)) {
    Write-Host "[ERROR] Configuration file not found: $configPath"
    Stop-Transcript
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$storageUrl = $config.StorageUrl
$sasToken = $config.SasToken

# Decode base64-encoded Mondoo token (avoids shell escaping issues)
$mondooTokenBase64 = $config.MondooTokenBase64
$mondooToken = if ($mondooTokenBase64) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($mondooTokenBase64)) } else { '' }

Write-Host "Storage URL: $storageUrl"
Write-Host "SAS Token: [REDACTED - $(($sasToken).Length) chars]"
Write-Host "Mondoo Token: [REDACTED - $(($mondooToken).Length) chars]"

$tempDir = 'C:\VulnerableInstallers'

# Create temp directory for downloads
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# ---------------------------------------------
# Install vulnerable baseline from blob storage
# ---------------------------------------------
Write-Host '=== Installing Vulnerable Baseline from Blob Storage ==='

function Install-FromBlob {
    param(
        [string]$Name,
        [string]$BlobPath,
        [string]$InstallArgs,
        [string]$ExpectedPath,
        [string]$ExpectedVersion
    )

    Write-Host "--- Installing $Name ---"

    $url = "$storageUrl/$BlobPath$sasToken"
    $fileName = Split-Path $BlobPath -Leaf
    $localPath = Join-Path $tempDir $fileName

    try {
        # Download installer
        Write-Host "Downloading $Name from blob storage..."
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $localPath)
        Write-Host "Downloaded to $localPath"

        # Install based on file extension
        $extension = [System.IO.Path]::GetExtension($fileName).ToLower()

        if ($extension -eq '.msi') {
            Write-Host "Installing MSI: msiexec /i $localPath $InstallArgs"
            $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$localPath`" $InstallArgs" -Wait -PassThru -NoNewWindow
        } else {
            Write-Host "Installing EXE: $localPath $InstallArgs"
            $process = Start-Process -FilePath $localPath -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
        }

        Write-Host "Exit code: $($process.ExitCode)"

        # Wait for MSI to fully complete before next install
        Start-Sleep -Seconds 10

        # Verify installation

        if (Test-Path $ExpectedPath) {
            $fileInfo = Get-Item $ExpectedPath
            $actualVersion = $fileInfo.VersionInfo.ProductVersion
            if (-not $actualVersion) { $actualVersion = $fileInfo.VersionInfo.FileVersion }
            Write-Host "[OK] $Name installed at $ExpectedPath"
            Write-Host "     Version: $actualVersion (expected: $ExpectedVersion)"
        } else {
            Write-Host "[FAIL] $Name not found at expected path: $ExpectedPath"
        }
    } catch {
        Write-Host "[ERROR] Failed to install $Name : $_"
    }
}

# Install vulnerable applications from blob storage
if ($storageUrl -ne '') {
    # 7-Zip 23.01 (CVE-2024-11477, fixed in 24.07)
    Install-FromBlob -Name '7-Zip' `
        -BlobPath '7zip/7z2301-x64.exe' `
        -InstallArgs '/S' `
        -ExpectedPath 'C:\Program Files\7-Zip\7z.exe' `
        -ExpectedVersion '23.01'

    # Google Chrome 120.0.6099.109 (multiple CVEs)
    Install-FromBlob -Name 'Google Chrome' `
        -BlobPath 'chrome/googlechromestandaloneenterprise64-120.0.6099.109.msi' `
        -InstallArgs '/qn /norestart' `
        -ExpectedPath 'C:\Program Files\Google\Chrome\Application\chrome.exe' `
        -ExpectedVersion '120.0.6099.109'

    # Zoom 5.16.2 (CVE-2024-24691, fixed in 5.16.5)
    Install-FromBlob -Name 'Zoom' `
        -BlobPath 'zoom/ZoomInstallerFull-5-16-2.msi' `
        -InstallArgs 'ALLUSERS=1 /qn /norestart' `
        -ExpectedPath 'C:\Program Files\Zoom\bin\Zoom.exe' `
        -ExpectedVersion '5.16.2'

    # Adobe Reader DC 23.006.20380 (multiple CVEs)
    Install-FromBlob -Name 'Adobe Reader' `
        -BlobPath 'adobe/AcroRdrDC2300620380_en_US.exe' `
        -InstallArgs '/sAll /rs /msi EULA_ACCEPT=YES' `
        -ExpectedPath 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' `
        -ExpectedVersion '23.006.20380'

    # AdoptOpenJDK JRE 8u202 (CVE-2019-2699, fixed in 8u211)
    # Note: 8u202 uses old "AdoptOpenJDK" branding, newer versions use "Eclipse Adoptium"
    # Download from: https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jre_x64_windows_hotspot_8u202b08.msi
    Install-FromBlob -Name 'AdoptOpenJDK JRE 8' `
        -BlobPath 'java/OpenJDK8U-jre_x64_windows_hotspot_8u202b08.msi' `
        -InstallArgs '/qn /norestart' `
        -ExpectedPath 'C:\Program Files\AdoptOpenJDK\jre-8.0.202.08\bin\java.exe' `
        -ExpectedVersion '8.0.202'
} else {
    Write-Host '[SKIP] No installer storage URL provided - skipping vulnerable baseline'
}

# Disable Chrome auto-updates to keep vulnerable version
Write-Host '=== Disabling Auto-Updates ==='
try {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Google\Update' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Google\Update' -Name 'AutoUpdateCheckPeriodMinutes' -Value 0 -Type DWord
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Google\Update' -Name 'UpdateDefault' -Value 0 -Type DWord
    Write-Host 'Chrome auto-update disabled via policy'
} catch {
    Write-Host "Failed to disable Chrome updates: $_"
}

# Cleanup temp directory
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------
# Install cnspec (Mondoo agent) - AFTER vulnerable software
# ---------------------------------------------
Write-Host '=== Installing cnspec ==='

try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download the Mondoo install script
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1'))

    if ($mondooToken -ne '') {
        # Install cnspec with registration, service, and auto-update in one step
        Install-Mondoo -RegistrationToken $mondooToken -Service enable -UpdateTask enable -Time 12:00 -Interval 3
        Write-Host 'cnspec installed, registered, service enabled, and update task scheduled'
    } else {
        # Install cnspec without registration
        Install-Mondoo -Product cnspec
        Write-Host '[SKIP] No Mondoo token provided - installed without registration'
    }
} catch {
    Write-Host "cnspec installation failed: $_"
}

# ---------------------------------------------
# Configure RDP for Azure AD Login
# ---------------------------------------------
Write-Host '=== Configuring RDP for Azure AD Login ==='
try {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 0
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'SecurityLayer' -Value 0
    Write-Host 'NLA disabled for Azure AD RDP login'
} catch {
    Write-Host "RDP configuration failed: $_"
}

# ---------------------------------------------
# Trigger Intune MDM Auto-Enrollment
# ---------------------------------------------
Write-Host '=== Triggering Intune MDM Enrollment ==='
try {
    Start-Sleep -Seconds 30
    & "$env:windir\system32\deviceenroller.exe" /c /AutoEnrollMDM
    Write-Host 'MDM auto-enrollment triggered (user login still required)'
} catch {
    Write-Host "MDM enrollment trigger failed: $_"
}

# ---------------------------------------------
# Generate verification report
# ---------------------------------------------
Write-Host '=== Generating Verification Report ==='
$report = @{
    Timestamp = (Get-Date).ToString('o')
    Hostname = $env:COMPUTERNAME
    Applications = @()
}

$appsToVerify = @(
    @{Name='7-Zip'; Path='C:\Program Files\7-Zip\7z.exe'; ExpectedVersion='23.01'},
    @{Name='Chrome'; Path='C:\Program Files\Google\Chrome\Application\chrome.exe'; ExpectedVersion='120.0.6099.109'},
    @{Name='Zoom'; Path='C:\Program Files\Zoom\bin\Zoom.exe'; ExpectedVersion='5.16.2'},
    @{Name='Adobe Reader'; Path='C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'; ExpectedVersion='23.006.20380'},
    @{Name='AdoptOpenJDK JRE 8'; Path='C:\Program Files\AdoptOpenJDK\jre-8.0.202.08\bin\java.exe'; ExpectedVersion='8.0.202'}
)

foreach ($app in $appsToVerify) {
    $status = @{
        Name = $app.Name
        ExpectedVersion = $app.ExpectedVersion
        Installed = $false
        ActualVersion = 'N/A'
    }

    if (Test-Path $app.Path) {
        $status.Installed = $true
        $fileInfo = Get-Item $app.Path
        $status.ActualVersion = $fileInfo.VersionInfo.ProductVersion
        if (-not $status.ActualVersion) { $status.ActualVersion = $fileInfo.VersionInfo.FileVersion }
    }

    $report.Applications += $status
}

$report | ConvertTo-Json -Depth 3 | Set-Content -Path 'C:\vulnerable-baseline-report.json'
Write-Host 'Verification report saved to C:\vulnerable-baseline-report.json'

# Clean up config file (contains sensitive tokens)
Remove-Item -Path $configPath -Force -ErrorAction SilentlyContinue
Write-Host 'Cleaned up configuration file'

Write-Host '=== VM Setup Complete ==='
Stop-Transcript
