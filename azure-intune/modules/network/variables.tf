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

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
}

variable "subnet_address_prefix" {
  description = "Subnet address prefix"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_rdp_access" {
  description = "Enable RDP access from internet"
  type        = bool
  default     = false
}

variable "rdp_source_ip" {
  description = "Source IP address allowed for RDP access (e.g., '1.2.3.4'). If empty, RDP is open to all when enabled."
  type        = string
  default     = ""
}
