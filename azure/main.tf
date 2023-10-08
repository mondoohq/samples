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

locals {
  windows_user_data_cnspec = <<-EOT
    <powershell>
    $hello = "Hello World"
    $hello | Out-File C:\debug.txt
    </powershell>
  EOT
}
#    Set-ExecutionPolicy Unrestricted -Scope Process -Force;
#    Add-WindowsCapability -Online -Name OpenSSH.Server
#    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
#    Start-Service sshd
#    Set-Service -Name sshd -StartupType 'Automatic'
#    $NewPassword = ConvertTo-SecureString "${random_password.password.result}" -AsPlainText -Force
#    Set-LocalUser -Name Administrator -Password $NewPassword
#    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
#    iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1'));
#    Install-Mondoo -RegistrationToken '${var.mondoo_registration_token}' -Service enable -UpdateTask enable -Time 12:00 -Interval 3;
#    cnspec scan local --config C:\ProgramData\Mondoo\mondoo.yml;
#
#
  #windows_user_data = <<-EOT
  #  <powershell>
  #  Set-ExecutionPolicy Unrestricted -Scope Process -Force;
  #  Add-WindowsCapability -Online -Name OpenSSH.Server
  #  New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
  #  Start-Service sshd
  #  Set-Service -Name sshd -StartupType 'Automatic'
  #  $NewPassword = ConvertTo-SecureString "${var.windows_admin_password}" -AsPlainText -Force
  #  Set-LocalUser -Name Administrator -Password $NewPassword
  #  </powershell>
  #EOT
#}



resource "azurerm_resource_group" "rg" {
  name      = "rg-Lunalectric-container-escape-${random_string.suffix.result}"
  location  = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "attacker_vm-network" {
  name                = "Windows-VM-Vnet-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [azurerm_resource_group.rg]
}

# Create subnet
resource "azurerm_subnet" "attacker_vm-subnet" {
  name                 = "Windows-VM-Subnet-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.attacker_vm-network.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [azurerm_virtual_network.attacker_vm-network]
}

# Create public IPs
resource "azurerm_public_ip" "attacker_vm-publicip" {
  name                = "Windows-VM-PublicIP-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  depends_on = [azurerm_resource_group.rg]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "attacker_vm-nsg" {
  name                = "Windows-VM-NetworkSecurityGroup-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-all-inbound"
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
  name                = "Windows-VM-NIC-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "Windows-VM-NicConfiguration-${random_string.suffix.result}"
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

module "windows11" {
  source                            = "Azure/compute/azurerm"
  version                           = "5.3.0"

  vm_hostname                       = "${var.prefix}-windows11-${random_string.suffix.result}"
  is_windows_image                  = true

  vnet_subnet_id                    = azurerm_subnet.attacker_vm-subnet.id
  resource_group_name               = azurerm_resource_group.rg.name

  network_security_group            = azurerm_network_security_group.attacker_vm-nsg


  location                          = azurerm_resource_group.rg.location
  #network_interface_ids             = [azurerm_network_interface.attacker_vm-nic.id]
  vm_size                              = "Standard_DS2_v2"
  admin_username                    = "adminusercis"
  admin_password                    = random_password.password.result

  # disk
  delete_data_disks_on_termination  = true
  delete_os_disk_on_termination     = true
  data_sa_type                      = "Premium_LRS"

  boot_diagnostics                  = true

  vm_os_publisher = "MicrosoftWindowsDesktop"
  vm_os_offer     = "windows-10"
  vm_os_sku       = "win10-22h2-entn-g2"
  vm_os_version   = "latest"

}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "attacker_vm" {
  name                  = "Windows-VM-${random_string.suffix.result}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.attacker_vm-nic.id]
  size                  = "Standard_DS2_v2"
  admin_username      = "adminusercis"
  admin_password      = random_password.password.result

  os_disk {
    name                 = "Windows-VM-OsDisk-${random_string.suffix.result}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "center-for-internet-security-inc"
    offer     = "cis-windows-10-l1"
    sku       = "cis-windows-10-l1"
    version   = "latest"
  }

  plan {
    name = "cis-windows-10-l1"
    product = "cis-windows-10-l1"
    publisher = "center-for-internet-security-inc"
  }

  computer_name                   = "windows-${random_string.suffix.result}"

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
  depends_on = [azurerm_storage_account.mystorageaccount, azurerm_network_interface_security_group_association.attacker_vm-nic-nsg]

  custom_data = base64encode(local.windows_user_data_cnspec)

}

data "azurerm_client_config" "current"{}