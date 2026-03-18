#!/usr/bin/env bash
#
# Re-installs the vulnerable software baseline on the testbed VM.
# Use this after Intune has remediated the VM to reset it to its
# initial vulnerable state for re-testing.
#
# Usage: ./reinstall-vulnerable-software.sh
#
set -euo pipefail

# Read values from Terraform state
RG=$(terraform output -raw resource_group_name)
VM=$(terraform output -raw windows_workstation_1_name)
STORAGE_URL=$(terraform output -raw installer_storage_url)

# Generate a fresh SAS token for blob access
STORAGE_ACCOUNT=$(terraform output -raw installer_storage_account)
SAS=$(az storage container generate-sas \
  --account-name "$STORAGE_ACCOUNT" \
  --name "vulnerable-apps" \
  --permissions r \
  --expiry "$(date -u -v+1H '+%Y-%m-%dT%H:%MZ' 2>/dev/null || date -u -d '+1 hour' '+%Y-%m-%dT%H:%MZ')" \
  --output tsv)

echo "Re-installing vulnerable software on VM: $VM"
echo "  Resource Group: $RG"
echo "  Storage: $STORAGE_URL"
echo ""

az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM" \
  --command-id RunPowerShellScript \
  --scripts '
# 7-Zip 23.01 (CVE-2024-11477, fixed in 24.07)
# First uninstall any existing 7-Zip (winget-upgraded versions use MSI, not the NSIS EXE)
Write-Host "Uninstalling existing 7-Zip..."
$uninstalled = $false

# Try winget uninstall first (handles both MSI and EXE installations)
$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    Write-Host "Attempting winget uninstall..."
    winget uninstall --id 7zip.7zip --silent --accept-source-agreements 2>&1 | Write-Host
    $uninstalled = $true
}

# Fallback: try NSIS uninstaller (original EXE-based install)
if (-not $uninstalled) {
    $uninstaller = "C:\Program Files\7-Zip\Uninstall.exe"
    if (Test-Path $uninstaller) {
        Write-Host "Using NSIS uninstaller..."
        $p = Start-Process -FilePath $uninstaller -ArgumentList "/S" -Wait -PassThru -NoNewWindow
        Write-Host "Uninstall exit code: $($p.ExitCode)"
        $uninstalled = $true
    }
}

# Fallback: try MSI uninstall via registry (winget without winget CLI)
if (-not $uninstalled) {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $7zipEntry = Get-ItemProperty $regPaths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*7-Zip*" } | Select-Object -First 1
    if ($7zipEntry -and $7zipEntry.UninstallString) {
        Write-Host "Using registry uninstall: $($7zipEntry.UninstallString)"
        if ($7zipEntry.UninstallString -match "msiexec") {
            $productCode = $7zipEntry.UninstallString -replace ".*(\{[^}]+\}).*", '"$1"'
            $p = Start-Process msiexec.exe -ArgumentList "/x $productCode /qn" -Wait -PassThru -NoNewWindow
        } else {
            $p = Start-Process cmd.exe -ArgumentList "/c `"$($7zipEntry.UninstallString) /S`"" -Wait -PassThru -NoNewWindow
        }
        Write-Host "Uninstall exit code: $($p.ExitCode)"
        $uninstalled = $true
    }
}

if (-not $uninstalled) {
    Write-Host "No existing 7-Zip installation found, proceeding with install."
}
Start-Sleep -Seconds 3

$url = "'"$STORAGE_URL"'/7zip/7z2301-x64.exe?'"$SAS"'"
$installer = "C:\7z2301-x64.exe"

Write-Host "Downloading 7-Zip 23.01..."
$wc = New-Object System.Net.WebClient
$wc.Headers.Add("x-ms-version","2020-10-02")
$wc.DownloadFile($url, $installer)

Write-Host "Installing 7-Zip 23.01 (silent)..."
$p = Start-Process -FilePath $installer -ArgumentList "/S" -Wait -PassThru -NoNewWindow
Write-Host "Exit code: $($p.ExitCode)"

Remove-Item $installer -Force -ErrorAction SilentlyContinue

$version = (Get-Item "C:\Program Files\7-Zip\7z.exe").VersionInfo.ProductVersion
Write-Host "Installed version: $version"
'

echo ""
echo "Done."
