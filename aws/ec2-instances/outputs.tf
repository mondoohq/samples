output "vpc-name" {
  value = module.vpc.name
}

output "deployer_ip_address" {
  value = local.userIP
}

output "data_public_ip_address" {
  value = chomp(data.http.clientip.response_body)
}

# amazon2_instances
output "amazon2" {
  value = module.amazon2.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2.public_ip}"
}

output "amazon2_cnspec" {
  value = module.amazon2_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2_cnspec.public_ip}"
}

output "amazon2_cis" {
  value = module.amazon2_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2_cis.public_ip}"
}

output "amazon2_cis_cnspec" {
  value = module.amazon2_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2_cis_cnspec.public_ip}"
}

# amazon2023_instances
output "amazon2023" {
  value = module.amazon2023.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2023.public_ip}"
}

output "amazon2023_cnspec" {
  value = module.amazon2023_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.amazon2023_cnspec.public_ip}"
}

# rhel 7
output "rhel7" {
  value = module.rhel7.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel7.public_ip}"
}

output "rhel7_cnspec" {
  value = module.rhel7_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel7_cnspec.public_ip}"
}

# rhel7 cis
#output "rhel7_cis" {
#  value = module.rhel7_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel7_cis.public_ip}"
#}
#
#output "rhel7_cis_cnspec" {
#  value = module.rhel7_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel7_cis_cnspec.public_ip}"
#}


# rhel8
output "rhel8" {
  value = module.rhel8.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel8.public_ip}"
}

output "rhel8_cnspec" {
  value = module.rhel8_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel8_cnspec.public_ip}"
}

output "rhel8_cis" {
  value = module.rhel8_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel8_cis.public_ip}"
}

output "rhel8_cis_cnspec" {
  value = module.rhel8_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel8_cis_cnspec.public_ip}"
}

# rhel9
output "rhel9" {
  value = module.rhel9.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel9.public_ip}"
}

output "rhel9_cnspec" {
  value = module.rhel9_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.rhel9_cnspec.public_ip}"
}

# nginx on rhel9 cis
output "nginx_rhel9_cis" {
  value = module.nginx_rhel9_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.nginx_rhel9_cis.public_ip}"
}

output "nginx_rhel9_cis_cnspec" {
  value = module.nginx_rhel9_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.nginx_rhel9_cis_cnspec.public_ip}"
}

# ubuntu2004
output "ubuntu2004" {
  value = module.ubuntu2004.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2004.public_ip}"
}

output "ubuntu2004_cnspec" {
  value = module.ubuntu2004_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2004_cnspec.public_ip}"
}

output "ubuntu2004_cis" {
  value = module.ubuntu2004_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2004_cis.public_ip}"
}


output "ubuntu2004_cis_cnspec" {
  value = module.ubuntu2004_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2004_cis_cnspec.public_ip}"
}



# ubuntu2204
output "ubuntu2204" {
  value = module.ubuntu2204.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204.public_ip}"
}

output "ubuntu2204_cnspec" {
  value = module.ubuntu2204_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204_cnspec.public_ip}"
}

output "ubuntu2204_cis" {
  value = module.ubuntu2204_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204_cis.public_ip}"
}

output "ubuntu2204_cis_cnspec" {
  value = module.ubuntu2204_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204_cis_cnspec.public_ip}"
}


## ubuntu2204 arm
output "ubuntu2204_cis_arm" {
  value = module.ubuntu2204_cis_arm.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204_cis_arm.public_ip}"
}

output "ubuntu2204_cis_cnspec_arm" {
  value = module.ubuntu2204_cis_cnspec_arm.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ubuntu@${module.ubuntu2204_cis_cnspec_arm.public_ip}"
}



## debian10
#output "debian10_cis_cnspec" {
#  value = module.debian10_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian10_cis_cnspec.public_ip}"
#}

# debian11
output "debian11" {
  value = module.debian11.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian11.public_ip}"
}

output "debian11_cnspec" {
  value = module.debian11_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian11_cnspec.public_ip}"
}

output "debian11_cis" {
  value = module.debian11_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian11_cis.public_ip}"
}

output "debian11_cis_cnspec" {
  value = module.debian11_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian11_cis_cnspec.public_ip}"
}

# debian12
output "debian12" {
  value = module.debian12.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian12.public_ip}"
}

output "debian12_cnspec" {
  value = module.debian12_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} admin@${module.debian12_cnspec.public_ip}"
}

# suse15
output "suse15" {
  value = module.suse15.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.suse15.public_ip}"
}

output "suse15_cnspec" {
  value = module.suse15_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.suse15_cnspec.public_ip}"
}

output "suse15_cis" {
  value = module.suse15_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.suse15_cis.public_ip}"
}

output "suse15_cis_cnspec" {
  value = module.suse15_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.suse15_cis_cnspec.public_ip}"
}

# oracle7
# oracle7
output "oracle7" {
  value = module.oracle7.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle7.public_ip}"
}

output "oracle7_cnspec" {
  value = module.oracle7_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle7_cnspec.public_ip}"
}

output "oracle7_cis" {
  value = module.oracle7_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle7_cis.public_ip}"
}

output "oracle7_cis_cnspec" {
  value = module.oracle7_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle7_cis_cnspec.public_ip}"
}

# oracle8
output "oracle8" {
  value = module.oracle8.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle8.public_ip}"
}

output "oracle8_cnspec" {
  value = module.oracle8_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle8_cnspec.public_ip}"
}

output "oracle8_cis" {
  value = module.oracle8_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle8_cis.public_ip}"
}

output "oracle8_cis_cnspec" {
  value = module.oracle8_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} ec2-user@${module.oracle8_cis_cnspec.public_ip}"
}

# rocky9
output "rocky9" {
  value = module.rocky9.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} rocky@${module.rocky9.public_ip}"
}

output "rocky9_cnspec" {
  value = module.rocky9_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} rocky@${module.rocky9_cnspec.public_ip}"
}

output "rocky9_cis" {
  value = module.rocky9_cis.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} rocky@${module.rocky9_cis.public_ip}"
}

output "rocky9_cis_cnspec" {
  value = module.rocky9_cis_cnspec.public_ip == null ? "" : "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.aws_key_pair_name} rocky@${module.rocky9_cis_cnspec.public_ip}"
}

# windows2016
output "windows2016" {
  value = module.windows2016.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2016.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2016_cnspec" {
  value = module.windows2016_cnspec.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2016_cnspec.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2016_cis" {
  value = module.windows2016_cis.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2016_cis.public_ip}:3389 /h:2048 /w:2048 /p:'${rsadecrypt(module.windows2016_cis.password_data, file(var.ssh_key))}'"
}

output "windows2016_cis_cnspec" {
  value = module.windows2016_cis_cnspec.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2016_cis_cnspec.public_ip}:3389 /h:2048 /w:2048 /p:'${rsadecrypt(module.windows2016_cis_cnspec.password_data, file(var.ssh_key))}'"
}

# windows2019
output "windows2019" {
  value = module.windows2019.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2019.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2019_cnspec" {
  value = module.windows2019_cnspec.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2019_cnspec.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2019_cis" {
  value = module.windows2019_cis.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2019_cis.public_ip}:3389 /h:2048 /w:2048 /p:'${rsadecrypt(module.windows2019_cis.password_data, file(var.ssh_key))}'"
}

output "windows2019_cis_cnspec" {
  value = module.windows2019_cis_cnspec.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2019_cis_cnspec.public_ip}:3389 /h:2048 /w:2048 /p:'${rsadecrypt(module.windows2019_cis_cnspec.password_data, file(var.ssh_key))}'"
}

# windows2022
output "windows2022" {
  value = module.windows2022.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2022_cnspec" {
  value = module.windows2022_cnspec.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022_cnspec.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2022_cis" {
  value = module.windows2022_cis.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022_cis.public_ip}:3389 /h:2048 /w:2048 /p:'${rsadecrypt(module.windows2022_cis.password_data, file(var.ssh_key))}'"
}

output "windows2022_cis_cnspec" {
  value = module.windows2022_cis_cnspec.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022_cis_cnspec.public_ip}:3389 /h:2048 /w:2048 /p:'${rsadecrypt(module.windows2022_cis_cnspec.password_data, file(var.ssh_key))}'"
}

output "windows2022_german" {
  value = module.windows2022_german.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022_german.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}

output "windows2022_italian" {
  value = module.windows2022_italian.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.windows2022_italian.public_ip}:3389 /h:2048 /w:2048 /p:'${var.windows_admin_password}'"
}
# nginx on windows 2019
output "nginx_win2019_cnspec" {
  value = module.nginx_win2019_cnspec.public_ip == null ? "" : "xfreerdp /u:Administrator /v:${module.nginx_win2019_cnspec.public_ip}:3389 /h:1200 /w:1920 /p:'${var.windows_admin_password}'\n(This will take a couple minutes to become available...)"
}