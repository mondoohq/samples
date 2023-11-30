variable "resource_group_name_prefix" {
  default       = "rg"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default       = "eastus"
  description   = "Location of the resource group."
}

variable "tenant_id" {
  type = string
  description = "The tenant to use"
}

variable "subscription_id" {
  type = string
  description = "The subscription to use."
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "mondoo-security"
}

variable "vnet_address_space" {
  description = "The address space that is used the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "publicIP" {
  description = "Your home PublicIP to configure access to ec2 instances"
}

variable "windows_admin_username" {
  default = "adminuser"
}

variable "windows_admin_password" {
  default = "MondooSPM1!"
}

variable "create_windows10" {
  default = false
}

variable "create_windows11" {
  default = false
}