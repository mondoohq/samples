# ==============================================================================
# RESOURCE GROUP OUTPUTS
# ==============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.mondoo_testing.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.mondoo_testing.location
}

# ==============================================================================
# WEB APP OUTPUTS (Dynamic)
# ==============================================================================

output "web_apps" {
  description = "Map of all deployed web apps with their details"
  value = {
    for key, app in azurerm_linux_web_app.apps :
    key => {
      id               = app.id
      name             = app.name
      default_hostname = app.default_hostname
      config           = local.assets_map[key].config
      stack            = local.assets_map[key].stack
    }
  }
}

# ==============================================================================
# FUNCTION APP OUTPUTS (Dynamic - Merged Vanilla + Hardened)
# ==============================================================================

output "function_apps" {
  description = "Map of all deployed function apps with their details"
  value = merge(
    # Vanilla function apps
    {
      for key, func in azurerm_linux_function_app.functions_vanilla :
      key => {
        id               = func.id
        name             = func.name
        default_hostname = func.default_hostname
        config           = local.assets_map[key].config
        stack            = local.assets_map[key].stack
      }
    },
    # Hardened function apps
    {
      for key, func in azurerm_linux_function_app.functions_hardened :
      key => {
        id               = func.id
        name             = func.name
        default_hostname = func.default_hostname
        config           = local.assets_map[key].config
        stack            = local.assets_map[key].stack
      }
    }
  )
}

# ==============================================================================
# DEPLOYMENT SLOT OUTPUTS (Dynamic - Optional)
# ==============================================================================

output "web_app_slots" {
  description = "Map of all deployed web app slots (empty if slots not enabled)"
  value = {
    for key, slot in azurerm_linux_web_app_slot.app_slots :
    key => {
      id     = slot.id
      name   = slot.name
      config = local.assets_map[key].config
      stack  = local.assets_map[key].stack
    }
  }
}

output "function_app_slots" {
  description = "Map of all deployed function app slots (empty if slots not enabled)"
  value = merge(
    # Vanilla function app slots
    {
      for key, slot in azurerm_linux_function_app_slot.function_slots_vanilla :
      key => {
        id     = slot.id
        name   = slot.name
        config = local.assets_map[key].config
        stack  = local.assets_map[key].stack
      }
    },
    # Hardened function app slots
    {
      for key, slot in azurerm_linux_function_app_slot.function_slots_hardened :
      key => {
        id     = slot.id
        name   = slot.name
        config = local.assets_map[key].config
        stack  = local.assets_map[key].stack
      }
    }
  )
}

output "deployment_slots_enabled" {
  description = "Whether deployment slots are enabled and deployed"
  value       = local.deploy_slots
}

# ==============================================================================
# MONDOO SCAN COMMANDS (Dynamic)
# ==============================================================================

output "mondoo_scan_commands" {
  description = "Copy-paste Mondoo scan commands for each asset"
  value = merge(
    # Web App scan commands
    {
      for key, app in azurerm_linux_web_app.apps :
      "webapp_${key}" => "cnspec scan azure --subscription ${var.subscription_id} --discover app-services --asset-name ${app.name}"
    },
    # Function App scan commands - Vanilla
    {
      for key, func in azurerm_linux_function_app.functions_vanilla :
      "function_${key}" => "cnspec scan azure --subscription ${var.subscription_id} --discover functions --asset-name ${func.name}"
    },
    # Function App scan commands - Hardened
    {
      for key, func in azurerm_linux_function_app.functions_hardened :
      "function_${key}" => "cnspec scan azure --subscription ${var.subscription_id} --discover functions --asset-name ${func.name}"
    },
    # Web App Slot scan commands
    {
      for key, slot in azurerm_linux_web_app_slot.app_slots :
      "webapp_slot_${key}" => "cnspec scan azure --subscription ${var.subscription_id} --discover app-services --asset-name ${slot.name}"
    },
    # Function App Slot scan commands - Vanilla
    {
      for key, slot in azurerm_linux_function_app_slot.function_slots_vanilla :
      "function_slot_${key}" => "cnspec scan azure --subscription ${var.subscription_id} --discover functions --asset-name ${slot.name}"
    },
    # Function App Slot scan commands - Hardened
    {
      for key, slot in azurerm_linux_function_app_slot.function_slots_hardened :
      "function_slot_${key}" => "cnspec scan azure --subscription ${var.subscription_id} --discover functions --asset-name ${slot.name}"
    }
  )
}

output "mondoo_resource_ids" {
  description = "Full Azure Resource IDs for Mondoo scanning"
  value = merge(
    # Web App resource IDs
    {
      for key, app in azurerm_linux_web_app.apps :
      "webapp_${key}" => app.id
    },
    # Function App resource IDs - Vanilla
    {
      for key, func in azurerm_linux_function_app.functions_vanilla :
      "function_${key}" => func.id
    },
    # Function App resource IDs - Hardened
    {
      for key, func in azurerm_linux_function_app.functions_hardened :
      "function_${key}" => func.id
    },
    # Web App Slot resource IDs
    {
      for key, slot in azurerm_linux_web_app_slot.app_slots :
      "webapp_slot_${key}" => slot.id
    },
    # Function App Slot resource IDs - Vanilla
    {
      for key, slot in azurerm_linux_function_app_slot.function_slots_vanilla :
      "function_slot_${key}" => slot.id
    },
    # Function App Slot resource IDs - Hardened
    {
      for key, slot in azurerm_linux_function_app_slot.function_slots_hardened :
      "function_slot_${key}" => slot.id
    }
  )
}

# ==============================================================================
# SUMMARY OUTPUT
# ==============================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    resource_group   = azurerm_resource_group.mondoo_testing.name
    location         = azurerm_resource_group.mondoo_testing.location
    app_service_plan = azurerm_service_plan.webapp.name
    app_service_sku  = var.app_service_plan_sku
    storage_account  = azurerm_storage_account.function_storage.name
    
    configuration = {
      config_types_deployed = var.config_types_to_deploy
      stacks_deployed       = var.stacks_to_deploy
      deployment_slots_enabled = local.deploy_slots
    }
    
    asset_counts = {
      web_apps           = length(azurerm_linux_web_app.apps)
      function_apps      = length(azurerm_linux_function_app.functions_vanilla) + length(azurerm_linux_function_app.functions_hardened)
      web_app_slots      = length(azurerm_linux_web_app_slot.app_slots)
      function_app_slots = length(azurerm_linux_function_app_slot.function_slots_vanilla) + length(azurerm_linux_function_app_slot.function_slots_hardened)
      total_test_assets  = length(azurerm_linux_web_app.apps) + length(azurerm_linux_function_app.functions_vanilla) + length(azurerm_linux_function_app.functions_hardened) + length(azurerm_linux_web_app_slot.app_slots) + length(azurerm_linux_function_app_slot.function_slots_vanilla) + length(azurerm_linux_function_app_slot.function_slots_hardened)
    }

    deployed_web_apps = [
      for key, app in azurerm_linux_web_app.apps :
      "${app.name} (${local.assets_map[key].config}-${local.assets_map[key].stack})"
    ]

    deployed_function_apps = concat(
      [
        for key, func in azurerm_linux_function_app.functions_vanilla :
        "${func.name} (${local.assets_map[key].config}-${local.assets_map[key].stack})"
      ],
      [
        for key, func in azurerm_linux_function_app.functions_hardened :
        "${func.name} (${local.assets_map[key].config}-${local.assets_map[key].stack})"
      ]
    )
  }
}

# ==============================================================================
# NEXT STEPS OUTPUT
# ==============================================================================

output "next_steps" {
  description = "Instructions for next steps after deployment"
  value = <<-EOT
  
  ✅ Infrastructure deployed successfully!
  
  DEPLOYMENT CONFIGURATION:
  - App Service Plan SKU: ${var.app_service_plan_sku}
  - Config Types: ${join(", ", var.config_types_to_deploy)}
  - Language Stacks: ${join(", ", var.stacks_to_deploy)}
  - Deployment Slots: ${local.deploy_slots ? "ENABLED" : "DISABLED"}

  ASSET COUNTS:
  - Web Apps: ${length(azurerm_linux_web_app.apps)}
  - Function Apps: ${length(azurerm_linux_function_app.functions_vanilla) + length(azurerm_linux_function_app.functions_hardened)}
  - Web App Slots: ${length(azurerm_linux_web_app_slot.app_slots)}
  - Function App Slots: ${length(azurerm_linux_function_app_slot.function_slots_vanilla) + length(azurerm_linux_function_app_slot.function_slots_hardened)}
  - Total Test Assets: ${length(azurerm_linux_web_app.apps) + length(azurerm_linux_function_app.functions_vanilla) + length(azurerm_linux_function_app.functions_hardened) + length(azurerm_linux_web_app_slot.app_slots) + length(azurerm_linux_function_app_slot.function_slots_vanilla) + length(azurerm_linux_function_app_slot.function_slots_hardened)}

  NEXT STEPS:
  
  1. Review deployed resources:
     - Resource Group: ${azurerm_resource_group.mondoo_testing.name}
     - Location: ${azurerm_resource_group.mondoo_testing.location}
     - App Service Plan: ${azurerm_service_plan.webapp.name} (${var.app_service_plan_sku})
  
  2. Copy Mondoo scan commands:
     Run: terraform output -json mondoo_scan_commands | jq -r '.[]'
  
  3. Execute Mondoo scans (requires cnspec CLI):
     - Ensure you're authenticated: az login
     - Ensure Mondoo is configured: cnspec login
     - Run scan commands from step 2
  
  4. Review CIS compliance:
     - Vanilla assets should show ~10-20%% pass rate (expected failures)
     - Hardened assets should show ~85-95%% pass rate (CIS compliant)
  
  5. Clean up resources when done:
     Run: terraform destroy
  
  📊 Expected Monthly Cost:
     - ${var.app_service_plan_sku == "B1" ? "B1 (Basic): ~$18-23/month" : var.app_service_plan_sku == "S1" ? "S1 (Standard): ~$75-80/month" : "${var.app_service_plan_sku}: Check Azure pricing"}

  ${!local.deploy_slots ? "💡 TIP: To test deployment slots (CIS 2.2.x, 2.4.x), upgrade to S1 SKU in variables.tf" : ""}
  
  💡 FILTERING: You can filter assets by config type or language stack in terraform.tfvars

  EOT
}
