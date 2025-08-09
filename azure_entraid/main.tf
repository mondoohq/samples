resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$"
  min_lower = 1
  min_numeric = 1
  min_special = 1
  min_upper = 1
}

resource "azurerm_resource_group" "rg" {
  name      = "rg-${var.prefix}-vms-${random_string.suffix.result}"
  location  = var.resource_group_location
}