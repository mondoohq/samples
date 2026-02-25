output "vm_id" {
  description = "Virtual machine ID"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = azurerm_windows_virtual_machine.main.name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = azurerm_network_interface.main.private_ip_address
}

output "principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_windows_virtual_machine.main.identity[0].principal_id
}

output "nic_id" {
  description = "Network interface ID"
  value       = azurerm_network_interface.main.id
}

output "public_ip_address" {
  description = "Public IP address (if enabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : null
}
