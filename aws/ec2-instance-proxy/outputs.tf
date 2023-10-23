output "vpc-name" {
  value = module.vpc.name
}

# debian12
output "debian12" {
  value = module.debian12.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian12.public_ip}"
}

output "debian12_proxy" {
  value = module.debian12_proxy.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian12_proxy.public_ip}"
}

output "privat_proxy" {
  value = "private ip address of the proxy: ${module.debian12_proxy.private_ip}"
}

# windows2022
output "windows2022" {
  value = module.windows2022.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022.public_ip}:3389 /h:1500 /w:2048 /p:'${var.windows_admin_password}'"
}