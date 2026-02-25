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

# Windows Workstation VM 2
output "windows_workstation_2_id" {
  description = "Windows Workstation 2 VM ID"
  value       = module.windows_workstation_2.vm_id
}

output "windows_workstation_2_name" {
  description = "Windows Workstation 2 VM name"
  value       = module.windows_workstation_2.vm_name
}

output "windows_workstation_2_private_ip" {
  description = "Windows Workstation 2 private IP address"
  value       = module.windows_workstation_2.private_ip_address
}

output "windows_workstation_2_public_ip" {
  description = "Windows Workstation 2 public IP address (for RDP)"
  value       = module.windows_workstation_2.public_ip_address
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
