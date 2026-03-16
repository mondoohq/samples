variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hackathon-intune"
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
    Project   = "hackathon-intune"
    ManagedBy = "terraform"
    Purpose   = "persistent-storage"
    Layer     = "foundation"
  }
}
