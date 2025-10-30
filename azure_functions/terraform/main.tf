# ==============================================================================
# RESOURCE GROUP
# ==============================================================================

resource "azurerm_resource_group" "mondoo_testing" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ==============================================================================
# APP SERVICE PLAN (B1 - Basic Tier for Web Apps)
# ==============================================================================

resource "azurerm_service_plan" "webapp" {
  name                = local.app_service_plan_name
  resource_group_name = azurerm_resource_group.mondoo_testing.name
  location            = azurerm_resource_group.mondoo_testing.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = local.common_tags
}

# ==============================================================================
# STORAGE ACCOUNT (Required for Function Apps)
# ==============================================================================

resource "azurerm_storage_account" "function_storage" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.mondoo_testing.name
  location                 = azurerm_resource_group.mondoo_testing.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication

  tags = local.common_tags
}

# ==============================================================================
# LINUX WEB APPS - DYNAMIC (All Configurations & Language Stacks)
# ==============================================================================

resource "azurerm_linux_web_app" "apps" {
  for_each = {
    for key, asset in local.assets_map :
    key => asset
    if asset.type == "webapp"
  }

  name                = "${local.resource_prefix}-app-webapp-${each.value.config}-${each.value.stack}-${local.suffix}"
  resource_group_name = azurerm_resource_group.mondoo_testing.name
  location            = azurerm_resource_group.mondoo_testing.location
  service_plan_id     = azurerm_service_plan.webapp.id

  # Configuration-dependent settings
  https_only                                 = each.value.config == "hardened" ? true : false
  public_network_access_enabled              = each.value.config == "hardened" ? false : true
  client_certificate_enabled                 = each.value.config == "hardened" ? true : false
  client_certificate_mode                    = each.value.config == "hardened" ? "Required" : "Optional"
  ftp_publish_basic_authentication_enabled   = each.value.config == "hardened" ? false : true
  webdeploy_publish_basic_authentication_enabled = each.value.config == "hardened" ? false : true

  site_config {
    minimum_tls_version      = each.value.config == "hardened" ? var.hardened_min_tls_version : var.vanilla_min_tls_version
    ftps_state               = each.value.config == "hardened" ? var.hardened_ftps_state : var.vanilla_ftps_state
    remote_debugging_enabled = each.value.config == "hardened" ? false : true
    http2_enabled            = each.value.config == "hardened" ? true : false
    vnet_route_all_enabled   = false  # No VNet in Phase 1

    # Dynamic application stack based on language
    # Note: Java requires 3 parameters (java_version, java_server, java_server_version)
    application_stack {
      python_version = each.value.stack == "python" ? local.language_versions[each.value.config].python : null
      php_version    = each.value.stack == "php" ? local.language_versions[each.value.config].php : null

      # Java requires all three parameters
      java_version        = each.value.stack == "java" ? local.language_versions[each.value.config].java : null
      java_server         = each.value.stack == "java" ? local.java_server_config[each.value.config].server : null
      java_server_version = each.value.stack == "java" ? local.java_server_config[each.value.config].server_version : null
    }

    cors {
      allowed_origins = each.value.config == "hardened" ? var.hardened_cors_allowed_origins : var.vanilla_cors_allowed_origins
    }
  }

  # Managed identity only for hardened
  dynamic "identity" {
    for_each = each.value.config == "hardened" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Note: auth_settings_v2 deferred to Phase 2 - CIS 2.1.12
  # Note: VNet integration deferred to Phase 2 - CIS 2.1.18

  tags = merge(
    each.value.config == "hardened" ? local.hardened_tags : local.vanilla_tags,
    {
      AssetCategory = "webapp"
      LanguageStack = each.value.stack
    }
  )
}

# ==============================================================================
# LINUX FUNCTION APPS - VANILLA (Uses Storage Account Access Key)
# NOTE: storage_account_access_key and storage_uses_managed_identity are mutually
#       exclusive, so we need separate resources for vanilla vs hardened
# ==============================================================================

resource "azurerm_linux_function_app" "functions_vanilla" {
  for_each = {
    for key, asset in local.assets_map :
    key => asset
    if asset.type == "function" && asset.config == "vanilla"
  }

  name                = "${local.resource_prefix}-func-${each.value.config}-${each.value.stack}-${local.suffix}"
  resource_group_name = azurerm_resource_group.mondoo_testing.name
  location            = azurerm_resource_group.mondoo_testing.location
  service_plan_id     = azurerm_service_plan.webapp.id

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key

  # Vanilla (non-compliant) settings
  https_only                                 = false
  public_network_access_enabled              = true
  client_certificate_enabled                 = false
  client_certificate_mode                    = "Optional"
  ftp_publish_basic_authentication_enabled   = true
  webdeploy_publish_basic_authentication_enabled = true

  site_config {
    minimum_tls_version      = var.vanilla_min_tls_version
    ftps_state               = var.vanilla_ftps_state
    remote_debugging_enabled = true
    http2_enabled            = false
    vnet_route_all_enabled   = false  # No VNet in Phase 1

    # Dynamic application stack based on language
    # Note: Azure Functions only support Python and Java (PHP not supported)
    # Note: Function Apps only need java_version (NOT java_server/java_server_version like Web Apps)
    application_stack {
      python_version = each.value.stack == "python" ? local.language_versions["vanilla"].python : null
      java_version   = each.value.stack == "java" ? local.language_versions["vanilla"].java : null
    }

    cors {
      allowed_origins = var.vanilla_cors_allowed_origins
    }
  }

  # No managed identity for vanilla

  # Note: auth_settings_v2 deferred to Phase 2 - CIS 2.3.11
  # Note: VNet integration deferred to Phase 2 - CIS 2.3.14

  tags = merge(
    local.vanilla_tags,
    {
      AssetCategory = "functionapp"
      LanguageStack = each.value.stack
    }
  )
}

# ==============================================================================
# LINUX FUNCTION APPS - HARDENED (Uses Managed Identity)
# ==============================================================================

resource "azurerm_linux_function_app" "functions_hardened" {
  for_each = {
    for key, asset in local.assets_map :
    key => asset
    if asset.type == "function" && asset.config == "hardened"
  }

  name                = "${local.resource_prefix}-func-${each.value.config}-${each.value.stack}-${local.suffix}"
  resource_group_name = azurerm_resource_group.mondoo_testing.name
  location            = azurerm_resource_group.mondoo_testing.location
  service_plan_id     = azurerm_service_plan.webapp.id

  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_uses_managed_identity = true

  # Hardened (CIS-compliant) settings
  https_only                                 = true
  public_network_access_enabled              = false
  client_certificate_enabled                 = true
  client_certificate_mode                    = "Required"
  ftp_publish_basic_authentication_enabled   = false
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    minimum_tls_version      = var.hardened_min_tls_version
    ftps_state               = var.hardened_ftps_state
    remote_debugging_enabled = false
    http2_enabled            = true
    vnet_route_all_enabled   = false  # No VNet in Phase 1

    # Dynamic application stack based on language
    # Note: Azure Functions only support Python and Java (PHP not supported)
    # Note: Function Apps only need java_version (NOT java_server/java_server_version like Web Apps)
    application_stack {
      python_version = each.value.stack == "python" ? local.language_versions["hardened"].python : null
      java_version   = each.value.stack == "java" ? local.language_versions["hardened"].java : null
    }

    cors {
      allowed_origins = var.hardened_cors_allowed_origins
    }
  }

  # Managed identity for hardened
  identity {
    type = "SystemAssigned"
  }

  # Note: auth_settings_v2 deferred to Phase 2 - CIS 2.3.11
  # Note: VNet integration deferred to Phase 2 - CIS 2.3.14

  tags = merge(
    local.hardened_tags,
    {
      AssetCategory = "functionapp"
      LanguageStack = each.value.stack
    }
  )
}

# ==============================================================================
# WEB APP DEPLOYMENT SLOTS - DYNAMIC (All Configurations & Language Stacks)
# NOTE: Only deployed if SKU supports deployment slots (Standard S1 or higher)
# ==============================================================================

resource "azurerm_linux_web_app_slot" "app_slots" {
  for_each = local.deploy_slots ? {
    for key, asset in local.assets_map :
    key => asset
    if asset.type == "webapp"
  } : {}

  name           = local.slot_name
  app_service_id = azurerm_linux_web_app.apps[each.key].id

  # Configuration-dependent settings
  https_only                                 = each.value.config == "hardened" ? true : false
  public_network_access_enabled              = each.value.config == "hardened" ? false : true
  client_certificate_enabled                 = each.value.config == "hardened" ? true : false
  client_certificate_mode                    = each.value.config == "hardened" ? "Required" : "Optional"
  ftp_publish_basic_authentication_enabled   = each.value.config == "hardened" ? false : true
  webdeploy_publish_basic_authentication_enabled = each.value.config == "hardened" ? false : true

  site_config {
    minimum_tls_version      = each.value.config == "hardened" ? var.hardened_min_tls_version : var.vanilla_min_tls_version
    ftps_state               = each.value.config == "hardened" ? var.hardened_ftps_state : var.vanilla_ftps_state
    remote_debugging_enabled = each.value.config == "hardened" ? false : true
    http2_enabled            = each.value.config == "hardened" ? true : false
    vnet_route_all_enabled   = false  # No VNet in Phase 1

    # Dynamic application stack based on language
    # Note: Java requires 3 parameters (java_version, java_server, java_server_version)
    application_stack {
      python_version = each.value.stack == "python" ? local.language_versions[each.value.config].python : null
      php_version    = each.value.stack == "php" ? local.language_versions[each.value.config].php : null

      # Java requires all three parameters
      java_version        = each.value.stack == "java" ? local.language_versions[each.value.config].java : null
      java_server         = each.value.stack == "java" ? local.java_server_config[each.value.config].server : null
      java_server_version = each.value.stack == "java" ? local.java_server_config[each.value.config].server_version : null
    }

    cors {
      allowed_origins = each.value.config == "hardened" ? var.hardened_cors_allowed_origins : var.vanilla_cors_allowed_origins
    }
  }

  # Managed identity only for hardened
  dynamic "identity" {
    for_each = each.value.config == "hardened" ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Note: auth_settings_v2 deferred to Phase 2 - CIS 2.2.11

  tags = merge(
    each.value.config == "hardened" ? local.hardened_tags : local.vanilla_tags,
    {
      AssetCategory = "webapp-slot"
      LanguageStack = each.value.stack
    }
  )
}

# ==============================================================================
# FUNCTION APP DEPLOYMENT SLOTS - VANILLA (Uses Storage Account Access Key)
# NOTE: Only deployed if SKU supports deployment slots (Standard S1 or higher)
# NOTE: storage_account_access_key and storage_uses_managed_identity are mutually
#       exclusive, so we need separate resources for vanilla vs hardened
# ==============================================================================

resource "azurerm_linux_function_app_slot" "function_slots_vanilla" {
  for_each = local.deploy_slots ? {
    for key, asset in local.assets_map :
    key => asset
    if asset.type == "function" && asset.config == "vanilla"
  } : {}

  name            = local.slot_name
  function_app_id = azurerm_linux_function_app.functions_vanilla[each.key].id

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key

  # Vanilla (non-compliant) settings
  https_only                                 = false
  public_network_access_enabled              = true
  client_certificate_enabled                 = false
  client_certificate_mode                    = "Optional"
  ftp_publish_basic_authentication_enabled   = true
  webdeploy_publish_basic_authentication_enabled = true

  site_config {
    minimum_tls_version      = var.vanilla_min_tls_version
    ftps_state               = var.vanilla_ftps_state
    remote_debugging_enabled = true
    http2_enabled            = false
    vnet_route_all_enabled   = false  # No VNet in Phase 1

    # Dynamic application stack based on language
    # Note: Azure Functions only support Python and Java (PHP not supported)
    # Note: Function Apps only need java_version (NOT java_server/java_server_version like Web Apps)
    application_stack {
      python_version = each.value.stack == "python" ? local.language_versions["vanilla"].python : null
      java_version   = each.value.stack == "java" ? local.language_versions["vanilla"].java : null
    }

    cors {
      allowed_origins = var.vanilla_cors_allowed_origins
    }
  }

  # No managed identity for vanilla

  # Note: auth_settings_v2 deferred to Phase 2 - CIS 2.4.10

  tags = merge(
    local.vanilla_tags,
    {
      AssetCategory = "functionapp-slot"
      LanguageStack = each.value.stack
    }
  )
}

# ==============================================================================
# FUNCTION APP DEPLOYMENT SLOTS - HARDENED (Uses Managed Identity)
# NOTE: Only deployed if SKU supports deployment slots (Standard S1 or higher)
# ==============================================================================

resource "azurerm_linux_function_app_slot" "function_slots_hardened" {
  for_each = local.deploy_slots ? {
    for key, asset in local.assets_map :
    key => asset
    if asset.type == "function" && asset.config == "hardened"
  } : {}

  name            = local.slot_name
  function_app_id = azurerm_linux_function_app.functions_hardened[each.key].id

  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_uses_managed_identity = true

  # Hardened (CIS-compliant) settings
  https_only                                 = true
  public_network_access_enabled              = false
  client_certificate_enabled                 = true
  client_certificate_mode                    = "Required"
  ftp_publish_basic_authentication_enabled   = false
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    minimum_tls_version      = var.hardened_min_tls_version
    ftps_state               = var.hardened_ftps_state
    remote_debugging_enabled = false
    http2_enabled            = true
    vnet_route_all_enabled   = false  # No VNet in Phase 1

    # Dynamic application stack based on language
    # Note: Azure Functions only support Python and Java (PHP not supported)
    # Note: Function Apps only need java_version (NOT java_server/java_server_version like Web Apps)
    application_stack {
      python_version = each.value.stack == "python" ? local.language_versions["hardened"].python : null
      java_version   = each.value.stack == "java" ? local.language_versions["hardened"].java : null
    }

    cors {
      allowed_origins = var.hardened_cors_allowed_origins
    }
  }

  # Managed identity for hardened
  identity {
    type = "SystemAssigned"
  }

  # Note: auth_settings_v2 deferred to Phase 2 - CIS 2.4.10

  tags = merge(
    local.hardened_tags,
    {
      AssetCategory = "functionapp-slot"
      LanguageStack = each.value.stack
    }
  )
}

