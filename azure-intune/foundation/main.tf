# -----------------------------------------------------------------------------
# Foundation Infrastructure - Persistent Resources
# These resources survive testbed teardowns and rebuilds
# -----------------------------------------------------------------------------

resource "random_string" "deploy_suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  resource_prefix = "${var.project_name}-foundation-${random_string.deploy_suffix.result}"
}

# -----------------------------------------------------------------------------
# Resource Group for Persistent Storage
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "foundation" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Storage Account for Vulnerable Software Installers
# -----------------------------------------------------------------------------

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "installers" {
  name                     = "intuneinst${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.foundation.name
  location                 = azurerm_resource_group.foundation.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = var.tags
}

resource "azurerm_storage_container" "vulnerable_apps" {
  name                  = "vulnerable-apps"
  storage_account_name  = azurerm_storage_account.installers.name
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Azure AD App Registration for Intune API Access
# This is a long-lived resource that survives testbed rebuilds
# -----------------------------------------------------------------------------

data "azuread_client_config" "current" {}

resource "azuread_application" "intune_app" {
  display_name = "${var.project_name}-intune-api"
  owners       = [data.azuread_client_config.current.object_id]

  required_resource_access {
    # Microsoft Graph API
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    # DeviceManagementManagedDevices.ReadWrite.All
    resource_access {
      id   = "243333ab-4d21-40cb-a475-36241daa0842"
      type = "Role"
    }

    # DeviceManagementConfiguration.ReadWrite.All
    resource_access {
      id   = "9241abd9-d0e6-425a-bd4f-47ba86e767a4"
      type = "Role"
    }

    # DeviceManagementApps.ReadWrite.All
    resource_access {
      id   = "78145de6-330d-4800-a6ce-494ff2d33d07"
      type = "Role"
    }

    # Directory.Read.All
    resource_access {
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }

    # DeviceManagementScripts.ReadWrite.All (for Device Health Scripts beta API)
    resource_access {
      id   = "9255e99d-faf5-445e-bbf7-cb71482737c4"
      type = "Role"
    }
  }

  web {
    redirect_uris = ["http://localhost:8080/callback"]
  }
}

resource "azuread_service_principal" "intune_sp" {
  client_id                    = azuread_application.intune_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# Microsoft Graph Service Principal (for granting admin consent)
data "azuread_service_principal" "msgraph" {
  client_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
}

# Grant admin consent for DeviceManagementManagedDevices.ReadWrite.All
resource "azuread_app_role_assignment" "intune_devices" {
  app_role_id         = "243333ab-4d21-40cb-a475-36241daa0842"
  principal_object_id = azuread_service_principal.intune_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant admin consent for DeviceManagementConfiguration.ReadWrite.All
resource "azuread_app_role_assignment" "intune_config" {
  app_role_id         = "9241abd9-d0e6-425a-bd4f-47ba86e767a4"
  principal_object_id = azuread_service_principal.intune_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant admin consent for DeviceManagementApps.ReadWrite.All
resource "azuread_app_role_assignment" "intune_apps" {
  app_role_id         = "78145de6-330d-4800-a6ce-494ff2d33d07"
  principal_object_id = azuread_service_principal.intune_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant admin consent for Directory.Read.All
resource "azuread_app_role_assignment" "directory_read" {
  app_role_id         = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
  principal_object_id = azuread_service_principal.intune_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# Grant admin consent for DeviceManagementScripts.ReadWrite.All (Device Health Scripts beta API)
resource "azuread_app_role_assignment" "intune_scripts" {
  app_role_id         = "9255e99d-faf5-445e-bbf7-cb71482737c4"
  principal_object_id = azuread_service_principal.intune_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_application_password" "intune_app_secret" {
  application_id = azuread_application.intune_app.id
  display_name   = "terraform-managed"
  end_date       = timeadd(timestamp(), "8760h") # 1 year

  # Ignore changes to end_date since timestamp() changes every run
  lifecycle {
    ignore_changes = [end_date]
  }
}
