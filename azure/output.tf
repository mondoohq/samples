
output "windows_10" {
  value = module.windows10 == [] ? [""] : module.windows10[0].public_ip_dns_name
}

output "windows_11" {
  value = module.windows11 == [] ? [""] : module.windows11[0].public_ip_dns_name
}

output "username_password" {
  value = "Username: ${var.windows_admin_username}, Password: ${var.windows_admin_password}"
}