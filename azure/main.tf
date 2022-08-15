resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "rg" {
  name      = "rg-Lunalectric-container-escape-${random_string.suffix.result}"
  location  = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "attacker_vm-network" {
  name                = "Hacking-VM-Vnet-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "attacker_vm-subnet" {
  name                 = "Hacking-VM-Subnet-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.attacker_vm-network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "attacker_vm-publicip" {
  name                = "Hacking-VM-PublicIP-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "attacker_vm-nsg" {
  name                = "Hacking-VM-NetworkSecurityGroup-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow all inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "attacker_vm-nic" {
  name                = "Hacking-VM-NIC-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "Hacking-VM-NicConfiguration-${random_string.suffix.result}"
    subnet_id                     = azurerm_subnet.attacker_vm-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.attacker_vm-publicip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "attacker_vm-nic-nsg" {
  network_interface_id      = azurerm_network_interface.attacker_vm-nic.id
  network_security_group_id = azurerm_network_security_group.attacker_vm-nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag-storage-${random_string.suffix.result}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "attacker_vm_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the prepare shell
data "template_file" "prepare-hacking-vm" {
  template = file("${path.module}/templates/prepare-hacking-vm.tpl")
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "attacker_vm" {
  name                  = "Hacking-VM-${random_string.suffix.result}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.attacker_vm-nic.id]
  size                  = "Standard_DS1_v2"
  custom_data = base64encode(data.template_file.prepare-hacking-vm.rendered)

  os_disk {
    name                 = "Hacking-VM-OsDisk-${random_string.suffix.result}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "attacker-${random_string.suffix.result}"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.attacker_vm_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}

# create aks cluster
resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "Lunalectric-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "Lunalectric-${random_string.suffix.result}"
  kubernetes_version  = "1.22"

  default_node_pool {
    name       = "default"
    node_count = "2"
    vm_size    = "standard_d2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
