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
