# Random suffix for global uniqueness
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  # Determine if deployment slots are supported based on SKU
  # Basic (B1-B3) does NOT support deployment slots
  # Standard (S1-S3) and Premium support deployment slots
  slots_supported = can(regex("^(S[1-3]|P[1-3]v[2-3])$", var.app_service_plan_sku))

  # Deploy slots only if enabled AND SKU supports it
  deploy_slots = var.enable_deployment_slots && local.slots_supported

  # Naming convention: mondoo-<resource-type>-<category>-<config>-<language>-<suffix>
  resource_prefix = "mondoo"
  suffix          = random_string.suffix.result

  # ============================================================================
  # DYNAMIC ASSET GENERATION
  # ============================================================================

  # Define which stacks are supported by each asset type
  # Azure Functions do NOT support PHP - only Python, Java, Node, .NET, PowerShell
  # Web Apps support Python, PHP, Java, Node, .NET, Ruby, etc.
  webapp_stacks = [for stack in var.stacks_to_deploy : stack]  # All selected stacks
  function_stacks = [for stack in var.stacks_to_deploy : stack if stack != "php"]  # Exclude PHP

  # Generate combinations for Web Apps (supports all languages)
  webapp_combinations = [
    for combo in setproduct(var.config_types_to_deploy, ["webapp"], local.webapp_stacks) :
    {
      config = combo[0]
      type   = combo[1]
      stack  = combo[2]
    }
  ]

  # Generate combinations for Function Apps (no PHP support)
  function_combinations = [
    for combo in setproduct(var.config_types_to_deploy, ["function"], local.function_stacks) :
    {
      config = combo[0]
      type   = combo[1]
      stack  = combo[2]
    }
  ]

  # Combine all asset combinations
  all_asset_combinations = concat(local.webapp_combinations, local.function_combinations)

  # Create a map of assets for easy for_each usage
  # Key format: "config-type-stack" (e.g., "vanilla-webapp-python")
  assets_map = {
    for asset in local.all_asset_combinations :
    "${asset.config}-${asset.type}-${asset.stack}" => asset
  }

  # Helper function to get language version based on config and stack
  language_versions = {
    vanilla = {
      python = var.vanilla_python_version  # 3.7 (deprecated)
      php    = var.vanilla_php_version     # 7.4 (deprecated)
      java   = var.vanilla_java_version    # 11 (deprecated)
    }
    hardened = {
      python = var.hardened_python_version  # 3.13 (current)
      php    = var.hardened_php_version     # 8.3 (current)
      java   = var.hardened_java_version    # 17 (current)
    }
  }

  # ============================================================================
  # RESOURCE NAMING
  # ============================================================================

  # Resource Group Name
  resource_group_name = "${local.resource_prefix}-rg-${var.environment}-${var.location}"

  # App Service Plan Name
  app_service_plan_name = "${local.resource_prefix}-plan-webapp-${local.suffix}"

  # Storage Account Name (alphanumeric only, no hyphens)
  storage_account_name = "${local.resource_prefix}sa${var.environment}${local.suffix}"

  # Deployment Slot Name (constant for all slots)
  slot_name = "staging"

  # Common Tags
  common_tags = {
    Project       = "mondoo-cis-testing"
    Environment   = var.environment
    ManagedBy     = "terraform"
    Purpose       = "cis-benchmark-validation"
    Owner         = var.owner_email
    CostCenter    = "security-testing"
    AutoDelete    = "true"
    CreatedDate   = timestamp()
  }

  # Vanilla Configuration Tags
  vanilla_tags = merge(
    local.common_tags,
    {
      ConfigType    = "vanilla"
      CISCompliant  = "false"
    }
  )

  # Hardened Configuration Tags
  hardened_tags = merge(
    local.common_tags,
    {
      ConfigType    = "hardened"
      CISCompliant  = "true"
    }
  )
}

