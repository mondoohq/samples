variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cz-intune"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "cz-intune"
    ManagedBy = "terraform"
    Purpose   = "persistent-storage"
    Layer     = "foundation"
  }
}
