# -----------------------------------------------------------------------------
# Testbed Infrastructure - Ephemeral Resources
# These can be torn down and rebuilt without affecting foundation resources
# -----------------------------------------------------------------------------

resource "random_string" "deploy_suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  resource_prefix = var.environment != "" ? "${var.project_name}-${var.environment}-${random_string.deploy_suffix.result}" : "${var.project_name}-${random_string.deploy_suffix.result}"
}

# -----------------------------------------------------------------------------
# Reference Foundation State for Persistent Storage
# -----------------------------------------------------------------------------

data "terraform_remote_state" "foundation" {
  backend = "local"
  config = {
    path = "${path.module}/../foundation/terraform.tfstate"
  }
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# SAS Token for Foundation Storage (generated fresh each apply)
# -----------------------------------------------------------------------------

data "azurerm_storage_account" "installers" {
  name                = data.terraform_remote_state.foundation.outputs.installer_storage_account_name
  resource_group_name = data.terraform_remote_state.foundation.outputs.resource_group_name
}

data "azurerm_storage_account_sas" "installer_sas" {
  connection_string = data.azurerm_storage_account.installers.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "8760h") # 1 year

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# -----------------------------------------------------------------------------
# Network Module
# -----------------------------------------------------------------------------

module "network" {
  source = "../modules/network"

  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  resource_prefix       = local.resource_prefix
  vnet_address_space    = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  enable_rdp_access     = var.enable_rdp_access
  tags                  = var.tags
}

# -----------------------------------------------------------------------------
# Azure AD Client Config (for RBAC role assignments)
# App registration is now managed in foundation layer
# -----------------------------------------------------------------------------

data "azuread_client_config" "current" {}

# -----------------------------------------------------------------------------
# Windows 11 Workstation VM 1
# -----------------------------------------------------------------------------

module "windows_workstation_1" {
  source = "../modules/windows-vm"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix
  deploy_suffix       = random_string.deploy_suffix.result
  vm_name             = "workstation-1"
  vm_size             = var.vm_size
  subnet_id           = module.network.subnet_id
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  enable_public_ip    = var.enable_rdp_access

  # Windows 11 Enterprise
  image_publisher = "MicrosoftWindowsDesktop"
  image_offer     = "windows-11"
  image_sku       = "win11-23h2-ent"
  image_version   = "latest"

  mondoo_registration_token = var.mondoo_api_token != "" ? mondoo_registration_token.vm_token[0].result : ""

  # Installer blob storage from foundation
  installer_storage_url          = data.terraform_remote_state.foundation.outputs.installer_storage_url
  installer_sas_token            = data.azurerm_storage_account_sas.installer_sas.sas
  installer_storage_account_name = data.terraform_remote_state.foundation.outputs.installer_storage_account_name
  installer_storage_account_key  = data.azurerm_storage_account.installers.primary_access_key

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Windows 11 Workstation VM 2
# -----------------------------------------------------------------------------

module "windows_workstation_2" {
  source = "../modules/windows-vm"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  resource_prefix     = local.resource_prefix
  deploy_suffix       = random_string.deploy_suffix.result
  vm_name             = "workstation-2"
  vm_size             = var.vm_size
  subnet_id           = module.network.subnet_id
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  enable_public_ip    = var.enable_rdp_access

  # Windows 11 Enterprise
  image_publisher = "MicrosoftWindowsDesktop"
  image_offer     = "windows-11"
  image_sku       = "win11-23h2-ent"
  image_version   = "latest"

  mondoo_registration_token = var.mondoo_api_token != "" ? mondoo_registration_token.vm_token[0].result : ""

  # Installer blob storage from foundation
  installer_storage_url          = data.terraform_remote_state.foundation.outputs.installer_storage_url
  installer_sas_token            = data.azurerm_storage_account_sas.installer_sas.sas
  installer_storage_account_name = data.terraform_remote_state.foundation.outputs.installer_storage_account_name
  installer_storage_account_key  = data.azurerm_storage_account.installers.primary_access_key

  tags = var.tags
}

# -----------------------------------------------------------------------------
# RBAC Role Assignments for Entra ID RDP Login
# Users need "Virtual Machine Administrator Login" role to RDP with Entra ID
# -----------------------------------------------------------------------------

locals {
  # Use explicit principal ID if provided, otherwise fall back to current authenticated identity
  vm_admin_principal_id = var.vm_admin_principal_id != "" ? var.vm_admin_principal_id : data.azuread_client_config.current.object_id
}

# Assign Virtual Machine Administrator Login role to specified principal for both VMs
resource "azurerm_role_assignment" "vm_admin_login_1" {
  scope                = module.windows_workstation_1.vm_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = local.vm_admin_principal_id
}

resource "azurerm_role_assignment" "vm_admin_login_2" {
  scope                = module.windows_workstation_2.vm_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = local.vm_admin_principal_id
}
