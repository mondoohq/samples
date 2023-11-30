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

resource "azurerm_virtual_network" "vnet" {
  address_space       = [var.vnet_address_space]
  location            = var.resource_group_location
  name                = "host${random_string.suffix.result}-vn"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  count = 1

  # tflint-ignore: terraform_count_index_usage
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, count.index)]
  name                 = "host${random_string.suffix.result}-sn-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_network_security_group" "external_nsg" {
  location            = var.resource_group_location
  name                = "${azurerm_resource_group.rg.name}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "vm" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allow_all"
  network_security_group_name = azurerm_network_security_group.external_nsg.name
  priority                    = 101
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.rg.name
  description                 = "Allow all"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "${var.publicIP}"
  source_port_range           = "*"
}

module "windows10" {
  count               = var.create_windows10 ? 1 : 0
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  is_windows_image    = true
  vm_hostname         = "win10-${random_string.suffix.result}" // line can be removed if only one VM module per resource group
  admin_username      = "${var.windows_admin_username}"
  admin_password      = "${var.windows_admin_password}"
  vm_os_publisher     = "MicrosoftWindowsDesktop"
  vm_os_offer         = "windows-10"
  vm_os_sku           = "win10-22h2-entn-g2"
  vm_os_version       = "latest"
  public_ip_dns       = ["win10-simpleip-${random_string.suffix.result}"]
  vnet_subnet_id      = azurerm_subnet.subnet[0].id
  network_security_group = {
    id = azurerm_network_security_group.external_nsg.id
  }

  depends_on = [azurerm_resource_group.rg]
}

module "windows11" {
  count               = var.create_windows11 ? 1 : 0
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  is_windows_image    = true
  vm_hostname         = "win10-${random_string.suffix.result}" // line can be removed if only one VM module per resource group
  admin_username      = "${var.windows_admin_username}"
  admin_password      = "${var.windows_admin_password}"
  vm_os_publisher     = "MicrosoftWindowsDesktop"
  vm_os_offer         = "windows-11"
  vm_os_sku           = "win11-23h2-entn"
  vm_os_version       = "latest"
  public_ip_dns       = ["win11-simpleip-${random_string.suffix.result}"]
  vnet_subnet_id      = azurerm_subnet.subnet[0].id
  network_security_group = {
    id = azurerm_network_security_group.external_nsg.id
  }

  depends_on = [azurerm_resource_group.rg]
}