#!/usr/bin/env bash
#
# Triggers a cnspec scan on the testbed VM and displays the results.
#
# Usage: ./run-cnspec-scan.sh
#
set -euo pipefail

# Read values from Terraform state
RG=$(terraform output -raw resource_group_name)
VM=$(terraform output -raw windows_workstation_1_name)

echo "Running cnspec scan on VM: $VM"
echo "  Resource Group: $RG"
echo ""

az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM" \
  --command-id RunPowerShellScript \
  --scripts '
Write-Host "=== Starting cnspec scan ==="
Write-Host "Timestamp: $(Get-Date)"
$cnspec = "C:\Program Files\Mondoo\cnspec.exe"
if (-not (Test-Path $cnspec)) {
    Write-Host "[ERROR] cnspec not found at $cnspec"
    exit 1
}

& $cnspec scan --config "C:\ProgramData\Mondoo\mondoo.yml" 2>&1
Write-Host ""
Write-Host "=== Scan complete ==="
' --query "value[0].message" -o tsv
