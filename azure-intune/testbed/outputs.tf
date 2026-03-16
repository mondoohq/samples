# -----------------------------------------------------------------------------
# Testbed Outputs
# -----------------------------------------------------------------------------

# Installer Storage (from foundation)
output "installer_storage_account" {
  description = "Storage account name for vulnerable software installers"
  value       = data.terraform_remote_state.foundation.outputs.installer_storage_account_name
}

output "installer_storage_url" {
  description = "Blob endpoint URL for installer storage"
  value       = data.terraform_remote_state.foundation.outputs.installer_storage_url
}

# Mondoo (only if configured)
output "mondoo_space_id" {
  description = "Mondoo space ID"
  value       = var.mondoo_api_token != "" ? mondoo_space.intune_demo[0].id : ""
}

output "mondoo_space_mrn" {
  description = "Mondoo space MRN"
  value       = var.mondoo_api_token != "" ? mondoo_space.intune_demo[0].mrn : ""
}

output "mondoo_registration_token" {
  description = "Mondoo registration token for VMs"
  value       = var.mondoo_api_token != "" ? mondoo_registration_token.vm_token[0].result : ""
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the testbed resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the testbed resource group"
  value       = azurerm_resource_group.main.id
}

# Azure AD App Registration (from foundation)
output "azure_tenant_id" {
  description = "Azure AD tenant ID"
  value       = data.terraform_remote_state.foundation.outputs.azure_tenant_id
}

output "azure_client_id" {
  description = "Azure AD application (client) ID for Intune API access"
  value       = data.terraform_remote_state.foundation.outputs.azure_client_id
}

output "azure_client_secret" {
  description = "Azure AD application secret"
  value       = data.terraform_remote_state.foundation.outputs.azure_client_secret
  sensitive   = true
}

# Network
output "vnet_id" {
  description = "Virtual network ID"
  value       = module.network.vnet_id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = module.network.subnet_id
}

# Windows Workstation VM 1
output "windows_workstation_1_id" {
  description = "Windows Workstation 1 VM ID"
  value       = module.windows_workstation_1.vm_id
}

output "windows_workstation_1_name" {
  description = "Windows Workstation 1 VM name"
  value       = module.windows_workstation_1.vm_name
}

output "windows_workstation_1_private_ip" {
  description = "Windows Workstation 1 private IP address"
  value       = module.windows_workstation_1.private_ip_address
}

output "windows_workstation_1_public_ip" {
  description = "Windows Workstation 1 public IP address (for RDP)"
  value       = module.windows_workstation_1.public_ip_address
}

# Intune Device Group
output "intune_device_group_name" {
  description = "Entra ID dynamic group for Intune-managed devices"
  value       = azuread_group.intune_devices.display_name
}

output "intune_device_group_id" {
  description = "Entra ID dynamic group object ID"
  value       = azuread_group.intune_devices.object_id
}

# -----------------------------------------------------------------------------
# Intune Enrollment Instructions
# -----------------------------------------------------------------------------

output "intune_enrollment_instructions" {
  description = "Steps to complete Intune MDM enrollment"
  value       = <<-EOT

    ============================================================
    INTUNE MDM ENROLLMENT - MANUAL STEP REQUIRED
    ============================================================

    The VM is Azure AD joined. Without Azure AD Premium, Intune
    enrollment requires a manual step via RDP.

    PREREQUISITES:
      - An Entra ID user with an Intune license assigned
      - The user must NOT have MFA enabled (MFA blocks enrollment in RDP)
      - The user must have "Virtual Machine Administrator Login"
        RBAC role on the VM (already assigned for the deploying user)

    STEPS:
      1. RDP to ${module.windows_workstation_1.public_ip_address} with the Entra ID user credentials
         (username format: AzureAD\user@domain.com)
      2. In the VM, open Settings > Accounts > Access work or school
      3. Click Connect > "Enroll only in device management"
      4. Enter the Entra ID user credentials
      5. Verify enrollment: https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/DevicesMenu/~/mDMDevicesPreview

    VM DETAILS:
      Name:       ${module.windows_workstation_1.vm_name}
      Private IP: ${module.windows_workstation_1.private_ip_address}
      Local Admin: ${var.vm_admin_username} (cannot be used for Intune enrollment)

    RE-INSTALL VULNERABLE SOFTWARE:
      After Intune remediates the VM, run this script to re-install
      the vulnerable software baseline (7-Zip 23.01, CVE-2024-11477):

      ./reinstall-vulnerable-software.sh

    ============================================================
  EOT
}

# Environment file helper
output "env_file_content" {
  description = "Content for .env file (copy to backend/.env)"
  sensitive   = true
  value       = <<-EOT
    # Azure AD / Intune Configuration (from foundation)
    AZURE_TENANT_ID=${data.terraform_remote_state.foundation.outputs.azure_tenant_id}
    AZURE_CLIENT_ID=${data.terraform_remote_state.foundation.outputs.azure_client_id}
    AZURE_CLIENT_SECRET=${data.terraform_remote_state.foundation.outputs.azure_client_secret}

    # Mondoo Configuration (for vulnerability queries)
    MONDOO_API_TOKEN=${var.mondoo_api_token}
    MONDOO_SPACE_ID=${var.mondoo_api_token != "" ? mondoo_space.intune_demo[0].id : ""}
    MONDOO_SPACE_MRN=${var.mondoo_api_token != "" ? mondoo_space.intune_demo[0].mrn : ""}

    # Backend Configuration
    SERVER_PORT=8080
    LOG_LEVEL=debug
    POLL_INTERVAL_SECONDS=300
  EOT
}
