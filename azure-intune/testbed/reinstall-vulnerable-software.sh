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
