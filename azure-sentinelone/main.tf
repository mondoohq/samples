resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Generated only if var.windows_admin_password isn't set. Specials limited to
# a safe set Azure accepts (no quotes, no backslash) so it can't break shell
# escaping in commandToExecute or RDP login.
resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-=?@"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

locals {
  resource_prefix        = "${var.prefix}-${random_string.suffix.result}"
  windows_admin_password = coalesce(var.windows_admin_password, random_password.admin.result)

  # All Windows VMs to create. Toggle individual VMs via the create_* variables.
  # SKUs were chosen so they're publicly available on Azure Marketplace without
  # extra licensing. Verify with:
  #   az vm image list --publisher MicrosoftWindowsDesktop --offer windows-11 --all -o table
  #   az vm image list --publisher MicrosoftWindowsServer  --offer WindowsServer  --all -o table
  vm_definitions = {
    win10 = {
      enabled         = var.create_windows10
      short_name      = "win10"
      image_publisher = "MicrosoftWindowsDesktop"
      image_offer     = "windows-10"
      image_sku       = "win10-22h2-ent-g2"
      patch_mode      = "AutomaticByOS"
    }
    win11 = {
      enabled         = var.create_windows11
      short_name      = "win11"
      image_publisher = "MicrosoftWindowsDesktop"
      image_offer     = "windows-11"
      image_sku       = "win11-23h2-ent"
      patch_mode      = "AutomaticByOS"
    }
    win2022 = {
      enabled         = var.create_windows_server_2022
      short_name      = "win2022"
      image_publisher = "MicrosoftWindowsServer"
      image_offer     = "WindowsServer"
      image_sku       = "2022-datacenter-azure-edition"
      # Azure Edition is hotpatch-compatible; Azure requires this patch mode.
      patch_mode = "AutomaticByPlatform"
    }
    win2025 = {
      enabled         = var.create_windows_server_2025
      short_name      = "win2025"
      image_publisher = "MicrosoftWindowsServer"
      image_offer     = "WindowsServer"
      image_sku       = "2025-datacenter-azure-edition"
      # Azure Edition is hotpatch-compatible; Azure requires this patch mode.
      patch_mode = "AutomaticByPlatform"
    }
  }

  vms_to_create = { for k, v in local.vm_definitions : k => v if v.enabled }
}

# -----------------------------------------------------------------------------
# Shared resource group + network
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-${local.resource_prefix}-vms"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "allow_rdp" {
  name                        = "AllowRDPFromAdmin"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.publicIP
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -----------------------------------------------------------------------------
# Storage account for the SentinelOne installer
#
# We upload the .msi here and hand the VMs a read-only SAS URL. This avoids
# the auth-required S1 console URL and gives us a stable URL across re-applies.
# -----------------------------------------------------------------------------

resource "random_string" "storage_suffix" {
  length  = 10
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_storage_account" "installers" {
  name                            = "s1msi${random_string.storage_suffix.result}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_container" "installers" {
  name                  = "installers"
  storage_account_name  = azurerm_storage_account.installers.name
  container_access_type = "private"
}

locals {
  # The SentinelOne console hands you either an .msi or an .exe. Both work -
  # the install script picks the right invocation based on this extension.
  sentinelone_installer_extension = lower(reverse(split(".", var.sentinelone_installer_path))[0])
}

resource "azurerm_storage_blob" "sentinelone_msi" {
  name                   = "SentinelInstaller.${local.sentinelone_installer_extension}"
  storage_account_name   = azurerm_storage_account.installers.name
  storage_container_name = azurerm_storage_container.installers.name
  type                   = "Block"
  source                 = var.sentinelone_installer_path
  content_md5            = filemd5(var.sentinelone_installer_path)
}

# The install script lives in blob too. CSE downloads it via fileUris so
# we don't have to inline its (multi-KB) contents into commandToExecute,
# which is capped at ~8KB by cmd.exe. The script itself has no secrets.
resource "azurerm_storage_blob" "install_script" {
  name                   = "install-sentinelone.ps1"
  storage_account_name   = azurerm_storage_account.installers.name
  storage_container_name = azurerm_storage_container.installers.name
  type                   = "Block"
  source                 = "${path.module}/scripts/install-sentinelone.ps1"
  content_md5            = filemd5("${path.module}/scripts/install-sentinelone.ps1")
}

# Service-level SAS scoped to a single blob object, read-only, valid for
# ~5 years. Static dates keep the SAS stable across applies (no drift).
data "azurerm_storage_account_sas" "installer_sas" {
  connection_string = azurerm_storage_account.installers.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "2025-01-01T00:00:00Z"
  expiry = "2030-12-31T23:59:59Z"

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

locals {
  sentinelone_installer_url = "${azurerm_storage_blob.sentinelone_msi.url}${data.azurerm_storage_account_sas.installer_sas.sas}"
  sentinelone_script_url    = "${azurerm_storage_blob.install_script.url}${data.azurerm_storage_account_sas.installer_sas.sas}"
}

# -----------------------------------------------------------------------------
# Per-VM networking + compute
# -----------------------------------------------------------------------------

resource "azurerm_public_ip" "vm" {
  for_each = local.vms_to_create

  name                = "pip-${local.resource_prefix}-${each.value.short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${each.value.short_name}-${random_string.suffix.result}"
  tags                = var.tags
}

resource "azurerm_network_interface" "vm" {
  for_each = local.vms_to_create

  name                = "nic-${local.resource_prefix}-${each.value.short_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm[each.key].id
  }

  # Azure serializes writes against a subnet. Wait for the NSG association
  # to finish so the 4 parallel NIC creates don't race against it (and each
  # other) and get "Subnet not found" 400s.
  depends_on = [azurerm_subnet_network_security_group_association.nsg_assoc]
}

resource "azurerm_windows_virtual_machine" "vm" {
  for_each = local.vms_to_create

  name                = "vm-${local.resource_prefix}-${each.value.short_name}"
  computer_name       = substr(replace("${each.value.short_name}${random_string.suffix.result}", "-", ""), 0, 15)
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.windows_admin_username
  admin_password      = local.windows_admin_password
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.vm[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = each.value.image_publisher
    offer     = each.value.image_offer
    sku       = each.value.image_sku
    version   = "latest"
  }

  provision_vm_agent       = true
  enable_automatic_updates = true
  patch_mode               = each.value.patch_mode
}

# -----------------------------------------------------------------------------
# SentinelOne agent install via Custom Script Extension
# -----------------------------------------------------------------------------

resource "azurerm_virtual_machine_extension" "sentinelone" {
  for_each = local.vms_to_create

  name                       = "InstallSentinelOne"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[each.key].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  # fileUris: CSE downloads the install script to its working dir.
  # commandToExecute: write secrets to C:\setup-config.json (base64-wrapped to
  # avoid shell-escaping issues with tokens), then invoke the downloaded script.
  # Both are in protected_settings so the SAS URLs and the script command line
  # don't appear in `Get-AzVm` output.
  protected_settings = jsonencode({
    fileUris = [local.sentinelone_script_url]
    commandToExecute = join("", [
      "powershell -ExecutionPolicy Bypass -Command \"",
      "[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('",
      base64encode(jsonencode({
        InstallerUrl       = local.sentinelone_installer_url
        InstallerExtension = local.sentinelone_installer_extension
        SiteToken          = var.sentinelone_site_token
      })),
      "')) | Set-Content C:\\setup-config.json -Encoding UTF8; ",
      "& .\\install-sentinelone.ps1\""
    ])
  })

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }
}
