################################################################################
# Additional
################################################################################

#output "region" {
#  description = "AWS region"
#  value       = var.region
#}
#
#output "current-aws-account" {
#  description = "Current AWS account"
#  value       = data.aws_caller_identity.current.account_id
#}
#
#output "aws-availability-zones" {
#  description = "current aws availability zones"
#  value       = data.aws_availability_zones.available.names
#}

################################################################################
# Kali Infos
################################################################################

output "kali_linux_public_ip" {
  value = <<EOT

################################################################################
# KALI LINUX SSH:
################################################################################

Username and password:
kali:${random_string.suffix.result}

ssh command:
ssh kali@${module.kali.public_ip}

privat ip:
${module.kali.private_ip}

EOT
}

################################################################################
# Windows Infos
################################################################################

output "windows_public_ip" {
  value = <<EOT

################################################################################
# Windows RDP Access:
################################################################################
  
xfreerdp /u:Administrator /v:${module.windows-instance.public_ip}:3389 /h:2048 /w:2048 /p:'Password1!'

privat ip:
${module.windows-instance.private_ip}

EOT
}

################################################################################
# Kali Infos
################################################################################

output "ubuntu_k8s_public_ip" {
  value = <<EOT

################################################################################
# Ubuntu K8s LINUX SSH:
################################################################################

Username and password:
ubuntu:${random_string.suffix.result}

ssh command:
ssh ubuntu@${module.ubuntu-k8s-instance.public_ip}

privat ip:
${module.ubuntu-k8s-instance.private_ip}

EOT
}