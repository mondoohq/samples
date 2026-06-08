variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vm_name" {
  description = "VM name suffix (e.g., 'server', 'workstation')"
  type        = string
}

variable "deploy_suffix" {
  description = "Short unique suffix for the deployment (used in computer_name to avoid AAD collisions)"
  type        = string
  default     = ""
}

variable "computer_name_prefix" {
  description = "Short prefix for Windows computer name (max ~7 chars, combined with deploy_suffix and vm_name must stay under 15 chars)"
  type        = string
  default     = ""
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "subnet_id" {
  description = "Subnet ID for the VM NIC"
  type        = string
}

variable "admin_username" {
  description = "Admin username"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "image_publisher" {
  description = "VM image publisher"
  type        = string
}

variable "image_offer" {
  description = "VM image offer"
  type        = string
}

variable "image_sku" {
  description = "VM image SKU"
  type        = string
}

variable "image_version" {
  description = "VM image version"
  type        = string
  default     = "latest"
}

variable "mondoo_registration_token" {
  description = "Mondoo registration token for cnspec"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_public_ip" {
  description = "Enable public IP for RDP access"
  type        = bool
  default     = false
}

variable "enable_setup_script" {
  description = "Enable setup script to install vulnerable software and cnspec"
  type        = bool
  default     = true
}

variable "installer_storage_url" {
  description = "Base URL for blob storage containing vulnerable software installers"
  type        = string
  default     = ""
}

variable "installer_sas_token" {
  description = "SAS token for accessing installer blobs"
  type        = string
  sensitive   = true
  default     = ""
}

variable "installer_storage_account_name" {
  description = "Storage account name for installer blobs"
  type        = string
  default     = ""
}

variable "installer_storage_account_key" {
  description = "Storage account key for installer blobs"
  type        = string
  sensitive   = true
  default     = ""
}
