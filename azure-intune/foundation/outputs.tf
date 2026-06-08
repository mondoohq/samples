# -----------------------------------------------------------------------------
# Foundation Outputs
# These are consumed by the testbed via terraform_remote_state
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Foundation resource group name"
  value       = azurerm_resource_group.foundation.name
}

output "resource_group_id" {
  description = "Foundation resource group ID"
  value       = azurerm_resource_group.foundation.id
}

output "installer_storage_account_name" {
  description = "Storage account name for vulnerable software installers"
  value       = azurerm_storage_account.installers.name
}

output "installer_storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.installers.id
}

output "installer_blob_endpoint" {
  description = "Primary blob endpoint for installer storage"
  value       = azurerm_storage_account.installers.primary_blob_endpoint
}

output "installer_storage_url" {
  description = "Full URL to the vulnerable-apps container"
  value       = "${azurerm_storage_account.installers.primary_blob_endpoint}vulnerable-apps"
}

output "installer_primary_access_key" {
  description = "Primary access key for installer storage"
  value       = azurerm_storage_account.installers.primary_access_key
  sensitive   = true
}

output "installer_connection_string" {
  description = "Connection string for installer storage"
  value       = azurerm_storage_account.installers.primary_connection_string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Azure AD App Registration Outputs
# -----------------------------------------------------------------------------

output "azure_tenant_id" {
  description = "Azure AD tenant ID"
  value       = data.azuread_client_config.current.tenant_id
}

output "azure_client_id" {
  description = "Azure AD application (client) ID for Intune API access"
  value       = azuread_application.intune_app.client_id
}

output "azure_client_secret" {
  description = "Azure AD application secret"
  value       = azuread_application_password.intune_app_secret.value
  sensitive   = true
}

output "intune_app_object_id" {
  description = "Azure AD application object ID"
  value       = azuread_application.intune_app.object_id
}

output "intune_service_principal_id" {
  description = "Azure AD service principal object ID"
  value       = azuread_service_principal.intune_sp.object_id
}
