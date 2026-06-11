variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "mondoo-s1"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the VM subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "publicIP" {
  description = "Your public IP (CIDR) allowed to RDP into the VMs, e.g. '1.2.3.4/32'"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size for all VMs"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "windows_admin_username" {
  description = "Local admin username for the Windows VMs"
  type        = string
  default     = "adminuser"
}

variable "windows_admin_password" {
  description = "Local admin password for the Windows VMs. Leave null (the default) to generate a strong random password - retrieve it with `terraform output -raw rdp_credentials`. Override only if you need a specific value (>= 12 chars, Azure complexity rules)."
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.windows_admin_password == null || length(coalesce(var.windows_admin_password, "............")) >= 12
    error_message = "If set, password must be at least 12 characters."
  }
}

variable "sentinelone_site_token" {
  description = "SentinelOne scope token (formerly 'site token') used to register agents with the existing console. Find it in Sentinels > Agent management > Packages > 'Scope Token'."
  type        = string
  sensitive   = true
}

variable "sentinelone_installer_path" {
  description = "Local filesystem path to the SentinelOne Windows agent (.msi). Download it manually from the S1 console (Sentinels > Agent management > Packages) - Terraform uploads it to an Azure Storage Account and generates a read-only SAS URL the VMs use to fetch it."
  type        = string

  validation {
    condition     = fileexists(var.sentinelone_installer_path)
    error_message = "sentinelone_installer_path must point to an existing file."
  }
}

variable "create_windows10" {
  description = "Create the Windows 10 VM"
  type        = bool
  default     = true
}

variable "create_windows11" {
  description = "Create the Windows 11 VM"
  type        = bool
  default     = true
}

variable "create_windows_server_2022" {
  description = "Create the Windows Server 2022 VM"
  type        = bool
  default     = true
}

variable "create_windows_server_2025" {
  description = "Create the Windows Server 2025 VM"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "azure-sentinelone"
    ManagedBy = "terraform"
  }
}
