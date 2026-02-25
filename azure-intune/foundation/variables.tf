variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "intune-prototype"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "intune-prototype"
    ManagedBy = "terraform"
    Purpose   = "persistent-storage"
    Layer     = "foundation"
  }
}
