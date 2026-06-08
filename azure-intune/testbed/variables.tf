variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hackathon-intune"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "vm_admin_username" {
  description = "Admin username for Windows VMs"
  type        = string
  default     = "azureadmin"
}

variable "vm_admin_password" {
  description = "Admin password for Windows VMs. Generate with: openssl rand -base64 24"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.vm_admin_password) >= 16
    error_message = "Password must be at least 16 characters. Generate with: openssl rand -base64 24"
  }
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "mondoo_org_id" {
  description = "Mondoo organization ID (e.g., 'lunalectric')"
  type        = string
  default     = ""
}

variable "mondoo_api_token" {
  description = "Mondoo API token (if not set, Mondoo integration is skipped)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mondoo_space_name" {
  description = "Name for the Mondoo space"
  type        = string
  default     = "hackathon-intune"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "hackathon-intune"
    ManagedBy = "terraform"
    Purpose   = "windows-remediation-poc"
    Layer     = "testbed"
  }
}

variable "enable_rdp_access" {
  description = "Enable RDP access to VMs (adds public IP and opens port 3389)"
  type        = bool
  default     = false
}

variable "vm_admin_principal_id" {
  description = "Azure AD principal ID (user or group) to grant VM Administrator Login role. If empty, uses the current authenticated identity."
  type        = string
  default     = ""
}
