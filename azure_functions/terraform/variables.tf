# Azure Subscription Configuration
variable "subscription_id" {
  description = "Azure subscription ID where resources will be deployed"
  type        = string
}

# Location Configuration
variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

# Project Configuration
variable "project_name" {
  description = "Project identifier for resource naming"
  type        = string
  default     = "mondoo-cis"
}

variable "environment" {
  description = "Environment name (test, dev, prod)"
  type        = string
  default     = "test"
}

variable "owner_email" {
  description = "Email address of the resource owner"
  type        = string
  default     = ""
}

# Hardened Configuration - Language Versions
variable "hardened_python_version" {
  description = "Python version for hardened assets (CIS compliant)"
  type        = string
  default     = "3.13"
}

variable "hardened_php_version" {
  description = "PHP version for hardened assets (CIS compliant)"
  type        = string
  default     = "8.3"
}

variable "hardened_java_version" {
  description = "Java version for hardened assets (CIS compliant)"
  type        = string
  default     = "17"
}

variable "hardened_java_server" {
  description = "Java server type for hardened assets (JAVA=Java SE, TOMCAT, JBOSSEAP)"
  type        = string
  default     = "JAVA"  # Java SE for simplicity
}

variable "hardened_java_server_version" {
  description = "Java server version for hardened assets (SE for Java SE)"
  type        = string
  default     = "SE"  # Standard Edition
}

# Vanilla Configuration - Language Versions (Deprecated)
variable "vanilla_python_version" {
  description = "Python version for vanilla assets (deprecated)"
  type        = string
  default     = "3.7"
}

variable "vanilla_php_version" {
  description = "PHP version for vanilla assets (deprecated)"
  type        = string
  default     = "7.4"
}

variable "vanilla_java_version" {
  description = "Java version for vanilla assets (deprecated)"
  type        = string
  default     = "11"
}

variable "vanilla_java_server" {
  description = "Java server type for vanilla assets"
  type        = string
  default     = "JAVA"  # Java SE
}

variable "vanilla_java_server_version" {
  description = "Java server version for vanilla assets"
  type        = string
  default     = "SE"  # Standard Edition
}

# Security Configuration - Hardened
variable "hardened_min_tls_version" {
  description = "Minimum TLS version for hardened assets"
  type        = string
  default     = "1.2"
}

variable "hardened_ftps_state" {
  description = "FTP state for hardened assets"
  type        = string
  default     = "Disabled"
}

variable "hardened_cors_allowed_origins" {
  description = "CORS allowed origins for hardened assets"
  type        = list(string)
  default     = ["https://example.com"]
}

# Security Configuration - Vanilla
variable "vanilla_min_tls_version" {
  description = "Minimum TLS version for vanilla assets"
  type        = string
  default     = "1.0"
}

variable "vanilla_ftps_state" {
  description = "FTP state for vanilla assets"
  type        = string
  default     = "AllAllowed"
}

variable "vanilla_cors_allowed_origins" {
  description = "CORS allowed origins for vanilla assets"
  type        = list(string)
  default     = ["*"]
}

# App Service Plan Configuration
variable "app_service_plan_sku" {
  description = <<-EOT
    SKU for App Service Plan. Choose based on your needs:

    Option 1 - Cost Optimized (No Deployment Slots):
      - SKU: "B1" (Basic) - ~$13/month
      - Supports: Web Apps and Function Apps only
      - Does NOT support: Deployment slots
      - Total assets: 4 (2 Web Apps + 2 Function Apps)
      - Use case: Budget-constrained testing, ~90% CIS coverage

    Option 2 - Full Testing (With Deployment Slots):
      - SKU: "S1" (Standard) - ~$70/month
      - Supports: Web Apps, Function Apps, AND Deployment Slots
      - Total assets: 6 (2 Web Apps + 2 Function Apps + 2 Slots)
      - Use case: Complete testing with deployment slot controls (CIS 2.2.x, 2.4.x)

    IMPORTANT: Deployment slots require Standard (S1) or higher!
    Azure Basic (B1) does NOT support deployment slots.
  EOT
  type        = string
  default     = "S1"  # Default to S1 for full testing with deployment slots

  validation {
    condition     = can(regex("^(B1|B2|B3|S1|S2|S3|P1v2|P2v2|P3v2|P1v3|P2v3|P3v3)$", var.app_service_plan_sku))
    error_message = "App Service Plan SKU must be a valid Linux SKU (B1-B3, S1-S3, or Premium)."
  }
}

variable "enable_deployment_slots" {
  description = <<-EOT
    Enable deployment slots for testing CIS controls 2.2.x (App Service Slots) and 2.4.x (Function Slots).

    NOTE: Requires Standard (S1) or higher SKU. Will be automatically disabled if using Basic (B1) SKU.

    Set to false if using B1 SKU to avoid deployment errors.
  EOT
  type        = bool
  default     = true  # Default to true, will deploy slots if SKU supports it
}

# Storage Account Configuration
variable "storage_account_tier" {
  description = "Storage account tier for Function Apps"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

# Asset Filtering Configuration
variable "config_types_to_deploy" {
  description = <<-EOT
    Which configuration types to deploy (vanilla, hardened, or both).

    Options:
    - ["vanilla", "hardened"] - Deploy both configurations (default, full testing)
    - ["vanilla"] - Deploy only non-compliant configurations
    - ["hardened"] - Deploy only CIS-compliant configurations

    Total assets = count(config_types) × count(asset_types) × count(stacks)
  EOT
  type        = list(string)
  default     = ["vanilla", "hardened"]

  validation {
    condition     = alltrue([for t in var.config_types_to_deploy : contains(["vanilla", "hardened"], t)])
    error_message = "config_types_to_deploy must only contain 'vanilla' and/or 'hardened'"
  }
}

variable "stacks_to_deploy" {
  description = <<-EOT
    Which language stacks to deploy (python, php, java, or all).

    Options:
    - ["python", "php", "java"] - Deploy all language stacks (default, comprehensive testing)
    - ["python"] - Deploy only Python assets (CIS 2.x.2)
    - ["php"] - Deploy only PHP assets (CIS 2.x.3)
    - ["java"] - Deploy only Java assets (CIS 2.x.1)
    - Any combination like ["python", "php"]

    Total assets = count(config_types) × count(asset_types) × count(stacks)
  EOT
  type        = list(string)
  default     = ["python", "php", "java"]

  validation {
    condition     = alltrue([for s in var.stacks_to_deploy : contains(["python", "php", "java"], s)])
    error_message = "stacks_to_deploy must only contain 'python', 'php', and/or 'java'"
  }
}
