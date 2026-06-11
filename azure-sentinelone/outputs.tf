output "resource_group_name" {
  description = "Name of the resource group hosting all VMs"
  value       = azurerm_resource_group.rg.name
}

output "vm_summary" {
  description = "Summary per VM: hostname, public IP, FQDN"
  value = {
    for k, vm in azurerm_windows_virtual_machine.vm : k => {
      name          = vm.name
      computer_name = vm.computer_name
      public_ip     = azurerm_public_ip.vm[k].ip_address
      fqdn          = azurerm_public_ip.vm[k].fqdn
      private_ip    = azurerm_network_interface.vm[k].private_ip_address
    }
  }
}

output "rdp_credentials" {
  description = "Local admin credentials for RDP (sensitive). Password is randomly generated unless windows_admin_password is set."
  sensitive   = true
  value = {
    username = var.windows_admin_username
    password = local.windows_admin_password
  }
}
