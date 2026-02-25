output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.main.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = azurerm_subnet.main.name
}

output "nsg_id" {
  description = "Network security group ID"
  value       = azurerm_network_security_group.main.id
}
