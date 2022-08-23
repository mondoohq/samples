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
  depends_on = [azurerm_resource_group.rg]
}

# Create subnet
resource "azurerm_subnet" "attacker_vm-subnet" {
  name                 = "Hacking-VM-Subnet-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.attacker_vm-network.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [azurerm_virtual_network.attacker_vm-network]
}

# Create public IPs
resource "azurerm_public_ip" "attacker_vm-publicip" {
  name                = "Hacking-VM-PublicIP-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  depends_on = [azurerm_resource_group.rg]
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
  depends_on = [azurerm_resource_group.rg]
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
  depends_on = [azurerm_resource_group.rg, azurerm_subnet.attacker_vm-subnet, azurerm_public_ip.attacker_vm-publicip]
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "attacker_vm-nic-nsg" {
  network_interface_id      = azurerm_network_interface.attacker_vm-nic.id
  network_security_group_id = azurerm_network_security_group.attacker_vm-nsg.id
  depends_on = [azurerm_network_interface.attacker_vm-nic, azurerm_network_security_group.attacker_vm-nsg]
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diaglunalectric${random_string.suffix.result}"
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

# Create virtual machine
resource "azurerm_linux_virtual_machine" "attacker_vm" {
  name                  = "Hacking-VM-${random_string.suffix.result}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.attacker_vm-nic.id]
  size                  = "Standard_DS1_v2"
  custom_data           = base64encode(templatefile("${path.module}/templates/prepare-hacking-vm.tpl", {}))

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
  depends_on = [azurerm_storage_account.mystorageaccount, azurerm_network_interface_security_group_association.attacker_vm-nic-nsg]
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
    node_count = "1"
    vm_size    = "standard_d2_v2"
    enable_node_public_ip = true
    tags = {
      keyvault = "keyvaultLunalectric-${random_string.suffix.result}"
    }
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
        key_data = tls_private_key.attacker_vm_ssh.public_key_openssh
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Mondoo Hacking Demo"
  }
  depends_on = [azurerm_resource_group.rg]
}

# configure keyvault
data "azurerm_client_config" "current"{}

resource "azurerm_key_vault" "keyvault" {
  name = "keyvaultLunalectric-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name = "standard"
  tags = {
    "createdBy"   = "hello@mondoo.com"
  }

  tenant_id = data.azurerm_client_config.current.tenant_id
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
      "List",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover",
      "List"
    ]
  }
  access_policy {
    object_id = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
    tenant_id = azurerm_kubernetes_cluster.cluster.identity[0].tenant_id
    secret_permissions = ["Get","List"]
    key_permissions = [
      "Create",
      "Get",
      "List",
    ]
  }

  depends_on = [azurerm_kubernetes_cluster.cluster]
}

resource "azurerm_key_vault_secret" "example-secret" {
  name         = "secret-sauce"
  value        = "example-pass"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "ssh-key" {
  name         = "private-ssh-key"
  value        = tls_private_key.attacker_vm_ssh.private_key_pem
  key_vault_id = azurerm_key_vault.keyvault.id
}

# configure aks nsg
# ISSUE https://github.com/hashicorp/terraform-provider-azurerm/issues/10233
# have to wait 15 min to get from azurerm_resources the node_resource_group of the cluster

#data "azurerm_resources" "cluster" {
#  resource_group_name = azurerm_kubernetes_cluster.cluster.node_resource_group
#
#  type = "Microsoft.Network/networkSecurityGroups"
#  depends_on = [azurerm_kubernetes_cluster.cluster]
#}
#
#resource "time_sleep" "wait_20_min" {
#  depends_on = [data.azurerm_resources.cluster]
#
#  create_duration = "20m"
#}
#
#resource "azurerm_network_security_rule" "nsg-cluster" {
#  name                        = "aks-ssh-inbound"
#  priority                    = 100
#  direction                   = "Inbound"
#  access                      = "Allow"
#  protocol                    = "Tcp"
#  source_port_range           = "*"
#  destination_port_range      = "22"
#  source_address_prefix       = "*"
#  destination_address_prefix  = "*"
#  resource_group_name         = azurerm_kubernetes_cluster.cluster.node_resource_group
#  network_security_group_name = data.azurerm_resources.cluster.resources.0.name
#  depends_on = [time_sleep.wait_20_min]
#}
