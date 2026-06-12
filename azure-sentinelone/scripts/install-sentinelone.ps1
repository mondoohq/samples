<#
.SYNOPSIS
    Downloads and installs the SentinelOne Windows agent, registering it
    with an existing SentinelOne console via a scope (site) token.
.DESCRIPTION
    Reads its config from C:\setup-config.json (written by the CSE
    bootstrap commandToExecute). The script itself contains no secrets,
    so it can be uploaded to Azure Blob as a plain artifact.

    Expected JSON keys:
      - InstallerUrl:       HTTPS URL of the installer (SAS-protected blob)
      - InstallerExtension: "msi" or "exe" - selects install command
      - SiteToken:          SentinelOne scope/site token
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$logFile = 'C:\sentinelone-install.log'
Start-Transcript -Path $logFile -Append

Write-Host "=== SentinelOne agent install started: $(Get-Date) ==="

$configPath = 'C:\setup-config.json'
if (-not (Test-Path $configPath)) {
    throw "Configuration file not found: $configPath"
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$installerUrl = $config.InstallerUrl
$siteToken    = $config.SiteToken
$extension    = ($config.InstallerExtension).ToLower()

if ([string]::IsNullOrWhiteSpace($installerUrl)) {
    throw 'InstallerUrl is empty - aborting.'
}
if ([string]::IsNullOrWhiteSpace($siteToken)) {
    throw 'SiteToken is empty - aborting.'
}
if ($extension -ne 'msi' -and $extension -ne 'exe') {
    throw "Unsupported InstallerExtension: '$extension' (expected 'msi' or 'exe')."
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installerPath = Join-Path $env:TEMP "SentinelInstaller.$extension"

Write-Host "Downloading installer to $installerPath"
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
Write-Host "Downloaded $((Get-Item $installerPath).Length) bytes"

if ($extension -eq 'msi') {
    $procArgs = @(
        '/i', "`"$installerPath`"",
        '/quiet',
        '/norestart',
        "SITE_TOKEN=$siteToken",
        '/L*v', 'C:\sentinelone-msi.log'
    )
    Write-Host 'Running msiexec...'
    $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList $procArgs -Wait -PassThru
} else {
    # SentinelOne EXE installer: -t <site_token> -q (silent)
    $procArgs = @('-t', $siteToken, '-q')
    Write-Host "Running $installerPath -t <REDACTED> -q"
    $proc = Start-Process -FilePath $installerPath -ArgumentList $procArgs -Wait -PassThru
}
Write-Host "Installer exit code: $($proc.ExitCode)"

# 0 = success, 3010 = success but reboot required.
if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
    throw "SentinelOne installation failed with exit code $($proc.ExitCode). See logs in C:\."
}

# Verify the agent service was registered and is starting. Give it a few
# seconds since the EXE installer's process can return before the service
# is fully registered.
Start-Sleep -Seconds 10
$service = Get-Service -Name 'SentinelAgent' -ErrorAction SilentlyContinue
if ($null -eq $service) {
    throw 'SentinelAgent service not found after install.'
}
Write-Host "SentinelAgent service status: $($service.Status)"

# OpenSSH Server: ships as a Windows Capability on Win10 1809+/Server 2019+.
# Adding it auto-creates the "OpenSSH-Server-In-TCP" firewall rule; we just
# need to enable + start sshd and make sure it survives reboots.
Write-Host '=== Enabling OpenSSH Server ==='
$sshCapability = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' |
    Select-Object -First 1
if ($null -eq $sshCapability) {
    Write-Warning 'OpenSSH.Server capability not found on this image - skipping SSH enablement.'
} else {
    if ($sshCapability.State -ne 'Installed') {
        Write-Host "Installing $($sshCapability.Name)"
        Add-WindowsCapability -Online -Name $sshCapability.Name | Out-Null
    } else {
        Write-Host "$($sshCapability.Name) already installed"
    }

    Set-Service -Name sshd -StartupType Automatic
    Start-Service sshd
    Write-Host "sshd service status: $((Get-Service sshd).Status)"

    # The capability install adds OpenSSH-Server-In-TCP, but only for the
    # profile the NIC was on at install time. Force it to all profiles so
    # SSH stays reachable if Windows reclassifies the network later.
    $fwRule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
    if ($null -eq $fwRule) {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
            -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow `
            -LocalPort 22 -Profile Any | Out-Null
    } else {
        Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Enabled True -Profile Any
    }
}

Write-Host "=== SentinelOne agent install completed: $(Get-Date) ==="
Stop-Transcript
