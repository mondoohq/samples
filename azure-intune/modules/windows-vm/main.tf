# -----------------------------------------------------------------------------
# Windows VM Module - Reusable for Server and Workstation
# -----------------------------------------------------------------------------

# Public IP (optional, for RDP access)
resource "azurerm_public_ip" "main" {
  count               = var.enable_public_ip ? 1 : 0
  name                = "pip-${var.resource_prefix}-${var.vm_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "main" {
  name                = "nic-${var.resource_prefix}-${var.vm_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.main[0].id : null
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-${var.resource_prefix}-${var.vm_name}"
  computer_name       = substr(replace("${var.computer_name_prefix}${var.deploy_suffix}${replace(var.vm_name, "workstation", "ws")}", "-", ""), 0, 15) # Max 15 chars for Windows
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.main.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Enable Azure AD join for Intune enrollment
  identity {
    type = "SystemAssigned"
  }

  # Allow Intune to manage the device
  provision_vm_agent                = true
  enable_automatic_updates          = false # We control updates via Intune
  vm_agent_platform_updates_enabled = true

  # Patch mode for Windows Update control
  patch_mode = "Manual"
}

# Azure AD Join extension with Intune MDM enrollment
resource "azurerm_virtual_machine_extension" "aad_join" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  # mdmId is set to empty string to join Azure AD WITHOUT triggering MDM
  # auto-enrollment (which requires Azure AD Premium and rolls back the join
  # on failure). MDM enrollment is handled separately by the setup script
  # using deviceenroller /c /AutoEnrollMDMUsingAADDeviceCredential.
  settings = jsonencode({
    mdmId = ""
  })

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }
}

# Setup script: installs vulnerable software, cnspec, and enrolls in Intune MDM
# Uses deviceenroller /c /AutoEnrollMDMUsingAADDeviceCredential for enrollment
# without requiring Azure AD Premium or user login.
resource "azurerm_virtual_machine_extension" "setup_script" {
  count                      = var.enable_setup_script ? 1 : 0
  name                       = "SetupScript"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  depends_on = [azurerm_virtual_machine_extension.aad_join]

  # Pass config as base64-encoded JSON and download+run script inline
  # MondooToken is base64-encoded separately to avoid shell escaping issues during cnspec login
  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(jsonencode({ StorageUrl = var.installer_storage_url, SasToken = var.installer_sas_token, MondooTokenBase64 = base64encode(var.mondoo_registration_token) }))}')) | Set-Content C:\\setup-config.json; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('x-ms-version','2020-10-02'); $scriptUrl = '${var.installer_storage_url}/scripts/vm-setup.ps1${var.installer_sas_token}'; $wc.DownloadFile($scriptUrl, 'C:\\vm-setup.ps1'); & C:\\vm-setup.ps1\""
  })

  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }
}

# Note: Setup script is stored in blob storage at scripts/vm-setup.ps1
# See modules/windows-vm/scripts/vm-setup.ps1 for the source
