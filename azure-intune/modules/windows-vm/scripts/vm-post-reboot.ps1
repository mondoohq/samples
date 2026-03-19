<#
.SYNOPSIS
    VM Setup Script Phase 2 - Post-Reboot Software Installation
.DESCRIPTION
    Runs after reboot via azurerm_virtual_machine_run_command.
    Installs vulnerable software baseline, cnspec agent, configures RDP,
    and verifies Intune MDM enrollment.
#>

$ErrorActionPreference = 'Continue'

# Create log file
$logFile = 'C:\setup-log-phase2.txt'
Start-Transcript -Path $logFile -Append

Write-Host '=== Starting VM Setup Phase 2: Post-Reboot ==='
Write-Host "Timestamp: $(Get-Date)"

# Read phase 2 configuration
$configPath = 'C:\setup-config-phase2.json'
if (-not (Test-Path $configPath)) {
    Write-Host "[ERROR] Phase 2 configuration file not found: $configPath"
    Stop-Transcript
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$storageUrl = $config.StorageUrl
$sasToken = $config.SasToken

# Decode base64-encoded Mondoo token
$mondooTokenBase64 = $config.MondooTokenBase64
$mondooToken = if ($mondooTokenBase64) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($mondooTokenBase64)) } else { '' }

Write-Host "Storage URL: $storageUrl"
Write-Host "SAS Token: [REDACTED - $(($sasToken).Length) chars]"
Write-Host "Mondoo Token: [REDACTED - $(($mondooToken).Length) chars]"

# ---------------------------------------------
# Wait for Intune MDM Enrollment
# After Azure AD join, wait for MDM enrollment to complete.
# ---------------------------------------------
Write-Host '=== Waiting for Intune MDM Enrollment ==='

$maxWait = 1800 # 30 minutes
$waited = 0
$enrolled = $false

while ($waited -lt $maxWait -and -not $enrolled) {
    $dsregOutput = & "$env:windir\system32\dsregcmd.exe" /status 2>&1 | Out-String

    # Check for MDM enrollment URL (confirms Intune enrollment)
    if ($dsregOutput -match 'MdmUrl\s*:\s*https://') {
        Write-Host "[OK] MDM enrollment detected after ${waited}s"
        $enrolled = $true
    } else {
        # Log progress with key status indicators
        $aadJoined = if ($dsregOutput -match 'AzureAdJoined\s*:\s*YES') { 'YES' } else { 'NO' }
        Write-Host "  Waiting for MDM enrollment... (${waited}s elapsed, AzureAdJoined: $aadJoined)"

        Start-Sleep -Seconds 30
        $waited += 30
    }
}

if ($enrolled) {
    Write-Host '[OK] Device is enrolled in Intune MDM'
} else {
    Write-Host '[WARN] MDM enrollment not confirmed after 30 min timeout - continuing with setup'
    Write-Host '[WARN] Check: Azure AD > Mobility (MDM/MAM) scope, Intune license, manual enrollment via RDP'
}

# Log full dsregcmd status for debugging
Write-Host '=== Device Registration Status ==='
& "$env:windir\system32\dsregcmd.exe" /status 2>&1

# ---------------------------------------------
# Install vulnerable baseline from blob storage
# ---------------------------------------------
Write-Host '=== Installing Vulnerable Baseline from Blob Storage ==='

$tempDir = 'C:\VulnerableInstallers'
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

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
} else {
    Write-Host '[SKIP] No installer storage URL provided - skipping vulnerable baseline'
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
# Generate verification report
# ---------------------------------------------
Write-Host '=== Generating Verification Report ==='
$report = @{
    Timestamp    = (Get-Date).ToString('o')
    Hostname     = $env:COMPUTERNAME
    IntuneEnrolled = $enrolled
    Applications = @()
}

$appsToVerify = @(
    @{Name='7-Zip'; Path='C:\Program Files\7-Zip\7z.exe'; ExpectedVersion='23.01'}
)

foreach ($app in $appsToVerify) {
    $status = @{
        Name            = $app.Name
        ExpectedVersion = $app.ExpectedVersion
        Installed       = $false
        ActualVersion   = 'N/A'
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

# Clean up config file (contains SAS token)
Remove-Item -Path $configPath -Force -ErrorAction SilentlyContinue
Write-Host 'Cleaned up phase 2 configuration file'

Write-Host '=== VM Setup Phase 2 Complete ==='
Stop-Transcript
