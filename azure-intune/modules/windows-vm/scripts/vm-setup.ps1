<#
.SYNOPSIS
    VM Setup Script - Installs vulnerable software baseline, cnspec agent, and enrolls in Intune
.DESCRIPTION
    Reads configuration from C:\setup-config.json and:
    - Waits for Azure AD join to complete
    - Enrolls the device in Intune MDM using AAD device credentials (no user login or Azure AD Premium required)
    - Installs vulnerable software from Azure blob storage
    - Installs Mondoo cnspec agent for security scanning
    - Configures RDP for Azure AD login
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

# ---------------------------------------------
# Wait for Azure AD Join to complete
# The AADLoginForWindows extension runs before this script,
# but we verify it completed successfully.
# ---------------------------------------------
Write-Host '=== Verifying Azure AD Join ==='

$maxWait = 300 # 5 minutes
$waited = 0
$aadJoined = $false

while ($waited -lt $maxWait -and -not $aadJoined) {
    $dsregOutput = & "$env:windir\system32\dsregcmd.exe" /status 2>&1 | Out-String
    if ($dsregOutput -match 'AzureAdJoined\s*:\s*YES') {
        $aadJoined = $true
        Write-Host "[OK] Device is Azure AD joined (confirmed after ${waited}s)"
    } else {
        Write-Host "  Waiting for Azure AD join... (${waited}s elapsed)"
        Start-Sleep -Seconds 15
        $waited += 15
    }
}

if (-not $aadJoined) {
    Write-Host '[ERROR] Azure AD join not detected after timeout - MDM enrollment will likely fail'
}

# ---------------------------------------------
# Configure Intune MDM enrollment URLs
# Pre-populate the MDM enrollment URLs in the registry so that manual
# enrollment via Settings UI works without extra configuration.
# ---------------------------------------------
Write-Host '=== Configuring Intune MDM Enrollment ==='

# Set MDM enrollment URLs in the registry (required when mdmId is not used in AAD join)
$dsregOutput = & "$env:windir\system32\dsregcmd.exe" /status 2>&1 | Out-String
$tenantId = if ($dsregOutput -match 'TenantId\s*:\s*([\w-]+)') { $Matches[1] } else { '' }
Write-Host "Detected Tenant ID: $tenantId"

if ($tenantId) {
    $mdmRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo\$tenantId"
    if (-not (Test-Path $mdmRegPath)) {
        New-Item -Path $mdmRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $mdmRegPath -Name 'MdmEnrollmentUrl' -Value 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc'
    Set-ItemProperty -Path $mdmRegPath -Name 'MdmTermsOfUseUrl' -Value 'https://portal.manage.microsoft.com/TermsofUse.aspx'
    Set-ItemProperty -Path $mdmRegPath -Name 'MdmComplianceUrl' -Value 'https://portal.manage.microsoft.com/?portalAction=Compliance'
    Write-Host '[OK] MDM enrollment URLs configured in registry'
} else {
    Write-Host '[ERROR] Could not detect tenant ID from dsregcmd - MDM enrollment may fail'
}

# NOTE: Automatic MDM enrollment (deviceenroller /c /AutoEnrollMDM) requires
# Azure AD Premium P1/P2 for MDM user scope configuration. Without Premium,
# Intune enrollment must be done manually via RDP:
#   Settings > Accounts > Access work or school > Connect > "Enroll only in device management"
Write-Host '[INFO] Intune MDM enrollment requires a manual step via RDP (no Azure AD Premium)'

# Log device registration status
Write-Host '=== Device Registration Status ==='
& "$env:windir\system32\dsregcmd.exe" /status 2>&1

# ---------------------------------------------
# Install winget (Windows Package Manager)
# The Azure Marketplace Windows 11 Enterprise image does not include
# winget. Intune remediation scripts depend on winget to detect and
# update software, so we must install it before Intune policies run.
# ---------------------------------------------
Write-Host '=== Installing winget ==='

$wingetDir = 'C:\WingetInstall'
New-Item -ItemType Directory -Force -Path $wingetDir | Out-Null

try {
    # Download VCLibs dependency
    $vcLibsUrl = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
    Invoke-WebRequest -Uri $vcLibsUrl -OutFile "$wingetDir\VCLibs.appx"

    # Download Microsoft.UI.Xaml dependency
    Invoke-WebRequest -Uri 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.6' -OutFile "$wingetDir\microsoft.ui.xaml.2.8.6.zip"
    Expand-Archive "$wingetDir\microsoft.ui.xaml.2.8.6.zip" -DestinationPath "$wingetDir\microsoft.ui.xaml" -Force
    $xamlAppx = Get-ChildItem "$wingetDir\microsoft.ui.xaml" -Recurse -Filter 'Microsoft.UI.Xaml.2.8.appx' |
        Where-Object { $_.FullName -match 'x64' } | Select-Object -First 1

    # Download winget
    $wingetUrl = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
    Invoke-WebRequest -Uri $wingetUrl -OutFile "$wingetDir\winget.msixbundle"

    # Install as provisioned package (available to all users)
    $deps = @("$wingetDir\VCLibs.appx")
    if ($xamlAppx) { $deps += $xamlAppx.FullName }
    Add-AppxProvisionedPackage -Online -PackagePath "$wingetDir\winget.msixbundle" -DependencyPackagePath $deps -SkipLicense -ErrorAction SilentlyContinue

    # Add to system PATH so scripts running as SYSTEM can find it
    $wingetExe = Get-ChildItem 'C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller*' -Recurse -Filter 'winget.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wingetExe) {
        $currentPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
        if ($currentPath -notlike "*$($wingetExe.DirectoryName)*") {
            [Environment]::SetEnvironmentVariable('PATH', "$currentPath;$($wingetExe.DirectoryName)", 'Machine')
        }
        Write-Host "[OK] winget installed at $($wingetExe.FullName)"
    } else {
        Write-Host '[WARN] winget package installed but exe not found'
    }
} catch {
    Write-Host "[ERROR] Failed to install winget: $_"
}

Remove-Item -Path $wingetDir -Recurse -Force -ErrorAction SilentlyContinue

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
# Generate verification report
# ---------------------------------------------
Write-Host '=== Generating Verification Report ==='
$report = @{
    Timestamp      = (Get-Date).ToString('o')
    Hostname       = $env:COMPUTERNAME
    AzureAdJoined  = $aadJoined
    IntuneEnrolled = $enrolled
    Applications   = @()
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

# Clean up config file (contains sensitive tokens)
Remove-Item -Path $configPath -Force -ErrorAction SilentlyContinue
Write-Host 'Cleaned up configuration file'

Write-Host '=== VM Setup Complete ==='
Stop-Transcript
