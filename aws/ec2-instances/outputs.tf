output "vpc-name" {
  value = module.vpc.name
}

# amazon2_instances
output "amazon2" {
  value = module.amazon2.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2.public_ip}"
}

output "amazon2_cis" {
  value = module.amazon2_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2_cis.public_ip}"
}

# rhel8
output "rhel8" {
  value = module.rhel8.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel8.public_ip}"
}

output "rhel8_cis" {
  value = module.rhel8_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel8_cis.public_ip}"
}

# rhel9
output "rhel9" {
  value = module.rhel9.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel9.public_ip}"
}

# ubuntu2204
output "ubuntu2204" {
  value = module.ubuntu2204.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204.public_ip}"
}

output "ubuntu2204_cis" {
  value = module.ubuntu2204_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204_cis.public_ip}"
}

# debian11
output "debian11" {
  value = module.debian11.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian11.public_ip}"
}

output "debian11_cis" {
  value = module.debian11_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian11_cis.public_ip}"
}

# suse15
output "suse15" {
  value = module.suse15.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.suse15.public_ip}"
}

output "suse15_cis" {
  value = module.suse15_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.suse15_cis.public_ip}"
}

# windows2022
output "windows2022" {
  value = module.windows2022.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2022_cis" {
  value = module.windows2022_cis.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022_cis.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
} 
