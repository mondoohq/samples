#!/usr/bin/env bash
#
# Forces Intune to sync and re-evaluate remediation scripts on the testbed VM.
#
# This restarts the Intune Management Extension (IME) service and triggers
# the MDM PushLaunch scheduled task. Together, these force Intune to:
#   - Check in with the Intune service
#   - Re-run detection scripts (remediation/HealthScripts)
#   - Execute remediation scripts if detection reports non-compliant
#   - Sync Win32 app deployments and PowerShell scripts
#
# Alternatively, you can trigger a remediation run from the Intune admin center:
#   Devices > Windows > select device > "..." > "Run remediation (preview)"
#   See docs/intune-run-remediation.png for a screenshot.
#
# Usage: ./trigger-intune-sync.sh
#
set -euo pipefail

# Read values from Terraform state
RG=$(terraform output -raw resource_group_name)
VM=$(terraform output -raw windows_workstation_1_name)

echo "Triggering Intune sync on VM: $VM"
echo "  Resource Group: $RG"
echo ""

az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM" \
  --command-id RunPowerShellScript \
  --scripts '
Write-Host "=== Triggering Intune Sync ==="
Write-Host "Timestamp: $(Get-Date)"

# 1. Restart the Intune Management Extension service
#    This re-initializes IME and triggers a full sync of scripts,
#    remediations, and Win32 apps.
$imeSvc = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
if ($imeSvc) {
    Write-Host "Restarting IntuneManagementExtension service (status: $($imeSvc.Status))..."
    Restart-Service IntuneManagementExtension -Force
    Start-Sleep -Seconds 5
    $imeSvc = Get-Service -Name IntuneManagementExtension
    Write-Host "[OK] IME service status: $($imeSvc.Status)"
} else {
    Write-Host "[WARN] IntuneManagementExtension service not found - is the device enrolled in Intune?"
}

# 2. Trigger the MDM PushLaunch scheduled task
#    This forces an MDM policy check-in (device config, compliance, etc.)
$pushTask = Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\*" -TaskName "PushLaunch" -ErrorAction SilentlyContinue
if ($pushTask) {
    Write-Host "Starting PushLaunch scheduled task..."
    $pushTask | Start-ScheduledTask
    Write-Host "[OK] PushLaunch task triggered"
} else {
    Write-Host "[WARN] PushLaunch task not found - device may not be MDM enrolled"
}

# 3. Show current remediation script status
Write-Host ""
Write-Host "=== Intune Remediation Scripts (HealthScripts) ==="
$healthScripts = Get-ChildItem "C:\Windows\IMECache\HealthScripts" -Directory -ErrorAction SilentlyContinue
if ($healthScripts) {
    foreach ($dir in $healthScripts) {
        $detect = Join-Path $dir.FullName "detect.ps1"
        $remediate = Join-Path $dir.FullName "remediate.ps1"
        $policyId = $dir.Name -replace "_\d+$", ""
        Write-Host "  Policy: $policyId"
        Write-Host "    Detection:   $(if (Test-Path $detect) { 'present' } else { 'missing' })"
        Write-Host "    Remediation: $(if (Test-Path $remediate) { 'present' } else { 'missing' })"
    }
} else {
    Write-Host "  No remediation scripts cached yet"
}

Write-Host ""
Write-Host "=== Sync triggered - remediation scripts will run within 1-2 minutes ==="
' --query "value[0].message" -o tsv

echo ""
echo "Done. Intune will re-evaluate remediation scripts within 1-2 minutes."
echo ""
echo "To trigger a specific remediation from the portal instead:"
echo "  Intune admin center > Devices > Windows > $VM > '...' > 'Run remediation (preview)'"
