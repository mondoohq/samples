output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_windows_virtual_machine.attacker_vm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.attacker_vm_ssh.private_key_pem
  sensitive = true
}

output "random_password" {
  value = random_password.password.result
  sensitive = true
}

output "summary" {
  value = <<EOT

Windows VM Public IP: ${azurerm_windows_virtual_machine.attacker_vm.public_ip_address}

Password: ${random_password.password.result}

Connection: xfreerdp /u:adminusercis /v:${azurerm_windows_virtual_machine.attacker_vm.public_ip_address}:3389 /h:1048 /w:1920 /p:'${random_password.password.result}' +clipboard


EOT
}
