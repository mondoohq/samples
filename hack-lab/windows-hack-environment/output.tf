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

output "hack_write_up" {
  value = <<EOT

# Windows DC Login

```bash
xfreerdp /u:Administrator /d:mondoo.hacklab /v:${module.windows-ad-instance.public_ip}:3389 /h:2048 /w:2048 /p:'${var.admin_password}'
```

private-ip: ${module.windows-ad-instance.private_ip}

# Windows Exchange Login

```bash
xfreerdp /u:Administrator /d:mondoo.hacklab /v:${module.windows-exchange.public_ip}:3389 /h:2048 /w:2048 /p:'${var.admin_password}'
```

private-ip: ${module.windows-exchange.private_ip}

# Windows DVWA Login

```bash
xfreerdp /u:Administrator /d:mondoo.hacklab /v:${module.windows-dvwa.public_ip}:3389 /h:2048 /w:2048 /p:'${var.admin_password}'
```

private-ip: ${module.windows-dvwa.private_ip}

# Kali Login

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}
```

Password: ${var.admin_password}

private-ip: ${module.kali.private_ip}

  EOT
}