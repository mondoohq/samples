resource "random_id" "instance_id" {
  byte_length = 4
}

# and assigned the IP address of the person who runs the terraform to the ource_address_prefix
data "http" "clientip" {
  url = "https://ipv4.icanhazip.com/"
}

locals {

  #userIP = "${chomp(data.http.clientip.response_body)}/32"
  userIP = var.publicIP == "" ? "${chomp(data.http.clientip.response_body)}/32" : var.publicIP

  linux_user_data = <<-EOT
    #!/bin/bash
    bash -c "$(curl -sSL https://install.mondoo.com/sh)"
    cnspec login --token ${var.mondoo_registration_token} --config /etc/opt/mondoo/mondoo.yml
    cnspec scan local --config /etc/opt/mondoo/mondoo.yml --asset-name $(uname -r)
  EOT

  windows_user_data_cnspec = <<-EOT
    <powershell>
    Set-ExecutionPolicy Unrestricted -Scope Process -Force;
    Add-WindowsCapability -Online -Name OpenSSH.Server
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    $NewPassword = ConvertTo-SecureString "${var.windows_admin_password}" -AsPlainText -Force
    Set-LocalUser -Name Administrator -Password $NewPassword
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1'));
    Install-Mondoo -RegistrationToken '${var.mondoo_registration_token}' -Service enable -UpdateTask enable -Time 12:00 -Interval 3;
    cnspec scan local --config C:\ProgramData\Mondoo\mondoo.yml;
    </powershell>
  EOT

  windows_user_data = <<-EOT
    <powershell>
    Set-ExecutionPolicy Unrestricted -Scope Process -Force;
    Add-WindowsCapability -Online -Name OpenSSH.Server
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
    $NewPassword = ConvertTo-SecureString "${var.windows_admin_password}" -AsPlainText -Force
    Set-LocalUser -Name Administrator -Password $NewPassword
    </powershell>
  EOT
}

////////////////////////////////
// VPC Configuration

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19.0"

  name = "${var.prefix}-${random_id.instance_id.id}"
  cidr = var.vpc_cidr

  azs                = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets    = var.vpc_private_subnets
  public_subnets     = var.vpc_public_subnets
  enable_nat_gateway = var.vpc_enable_nat_gateway
}

////////////////////////////////
// Linux Security Groups

module "linux_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.0"

  name        = "${var.prefix}-${random_id.instance_id.id}-linux-sg"
  description = "Security group for linux instances"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all from my ip"
      cidr_blocks = "10.0.0.0/8,${local.userIP}"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports (ipv4)"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

////////////////////////////////
// Linux Instances

// Amazon Linux 2023

module "amazon2023" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_amazon2023
  name                        = "${var.prefix}-amazon2023-${random_id.instance_id.id}"
  ami                         = data.aws_ami.amazon2023.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "amazon2023_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_amazon2023_cnspec
  name                        = "${var.prefix}-amazon2023-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.amazon2023.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Amazon Linux 2

module "amazon2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_amazon2
  name                        = "${var.prefix}-amazon2-${random_id.instance_id.id}"
  ami                         = data.aws_ami.amazon2.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "amazon2_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_amazon2_cnspec
  name                        = "${var.prefix}-amazon2-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.amazon2.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "amazon2_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_amazon2_cis
  name                        = "${var.prefix}-amazon2-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.amazon2_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "amazon2_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_amazon2_cis_cnspec
  name                        = "${var.prefix}-amazon2-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.amazon2_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Debian 10

module "debian10" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian10
  name                        = "${var.prefix}-debian10-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian10.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}
// Debian 11

module "debian11" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian11
  name                        = "${var.prefix}-debian11-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian11.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian11_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian11_cnspec
  name                        = "${var.prefix}-debian11-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian11.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "debian11_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian11_cis
  name                        = "${var.prefix}-debian11-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian11_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian11_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian11_cis_cnspec
  name                        = "${var.prefix}-debian11-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian11_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Debian 12

module "debian12" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian12
  name                        = "${var.prefix}-debian12-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian12_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian12_cnspec
  name                        = "${var.prefix}-debian12-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}


module "debian12_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian12_cis
  name                        = "${var.prefix}-debian12-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian12_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian12_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian12_cis_cnspec
  name                        = "${var.prefix}-debian12-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian12_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Debian 13

module "debian13" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian13
  name                        = "${var.prefix}-debian13-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian13.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian13_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian13_cnspec
  name                        = "${var.prefix}-debian13-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian13.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "debian13_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian13_cis
  name                        = "${var.prefix}-debian13-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian13_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian13_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_debian13_cis_cnspec
  name                        = "${var.prefix}-debian13-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian13_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Oracle 7

#module "oracle7" {
#  source  = "terraform-aws-modules/ec2-instance/aws"
#  version = "~> 5.7.1"
#
#  create                      = var.create_oracle7
#  name                        = "${var.prefix}-oracle7-${random_id.instance_id.id}"
#  ami                         = data.aws_ami.oracle7.id
#  instance_type               = var.linux_instance_type
#  vpc_security_group_ids      = [module.linux_sg.security_group_id]
#  subnet_id                   = module.vpc.public_subnets[0]
#  key_name                    = var.aws_key_pair_name
#  associate_public_ip_address = true
#}
#
#module "oracle7_cnspec" {
#  source  = "terraform-aws-modules/ec2-instance/aws"
#  version = "~> 5.7.1"
#
#  create                      = var.create_oracle7_cnspec
#  name                        = "${var.prefix}-oracle7-cnspec-${random_id.instance_id.id}"
#  ami                         = data.aws_ami.oracle7.id
#  instance_type               = var.linux_instance_type
#  vpc_security_group_ids      = [module.linux_sg.security_group_id]
#  subnet_id                   = module.vpc.public_subnets[0]
#  key_name                    = var.aws_key_pair_name
#  associate_public_ip_address = true
#  user_data                   = base64encode(local.linux_user_data)
#  user_data_replace_on_change = true
#}

#module "oracle7_cis" {
#  source  = "terraform-aws-modules/ec2-instance/aws"
#  version = "~> 5.7.1"
#
#  create                      = var.create_oracle7_cis
#  name                        = "${var.prefix}-oracle7-cis-${random_id.instance_id.id}"
#  ami                         = data.aws_ami.oracle7_cis.id
#  instance_type               = var.linux_instance_type
#  vpc_security_group_ids      = [module.linux_sg.security_group_id]
#  subnet_id                   = module.vpc.public_subnets[0]
#  key_name                    = var.aws_key_pair_name
#  associate_public_ip_address = true
#}

#module "oracle7_cis_cnspec" {
#  source  = "terraform-aws-modules/ec2-instance/aws"
#  version = "~> 5.7.1"
#
#  create                      = var.create_oracle7_cis_cnspec
#  name                        = "${var.prefix}-oracle7-cis-cnspec-${random_id.instance_id.id}"
#  ami                         = data.aws_ami.oracle7_cis.id
#  instance_type               = var.linux_instance_type
#  vpc_security_group_ids      = [module.linux_sg.security_group_id]
#  subnet_id                   = module.vpc.public_subnets[0]
#  key_name                    = var.aws_key_pair_name
#  associate_public_ip_address = true
#  user_data                   = base64encode(local.linux_user_data)
#  user_data_replace_on_change = true
#}

// Oracle 8 deprecated

#module "oracle8" {
#  source  = "terraform-aws-modules/ec2-instance/aws"
#  version = "~> 5.7.1"
#
#  create                      = var.create_oracle8
#  name                        = "${var.prefix}-oracle8-${random_id.instance_id.id}"
#  ami                         = data.aws_ami.oracle8.id
#  instance_type               = var.linux_instance_type
#  vpc_security_group_ids      = [module.linux_sg.security_group_id]
#  subnet_id                   = module.vpc.public_subnets[0]
#  key_name                    = var.aws_key_pair_name
#  associate_public_ip_address = true
#}
#
#module "oracle8_cnspec" {
#  source  = "terraform-aws-modules/ec2-instance/aws"
#  version = "~> 5.7.1"
#
#  create                      = var.create_oracle8_cnspec
#  name                        = "${var.prefix}-oracle8-cnspec-${random_id.instance_id.id}"
#  ami                         = data.aws_ami.oracle8.id
#  instance_type               = var.linux_instance_type
#  vpc_security_group_ids      = [module.linux_sg.security_group_id]
#  subnet_id                   = module.vpc.public_subnets[0]
#  key_name                    = var.aws_key_pair_name
#  associate_public_ip_address = true
#  user_data                   = base64encode(local.linux_user_data)
#  user_data_replace_on_change = true
#}

module "oracle8_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_oracle8_cis
  name                        = "${var.prefix}-oracle8-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.oracle8_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "oracle8_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_oracle8_cis_cnspec
  name                        = "${var.prefix}-oracle8-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.oracle8_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Oracle 9
module "oracle9" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_oracle9
  name                        = "${var.prefix}-oracle9-${random_id.instance_id.id}"
  ami                         = data.aws_ami.oracle9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "oracle9_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_oracle9_cnspec
  name                        = "${var.prefix}-oracle9-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.oracle9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "oracle9_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_oracle9_cis
  name                        = "${var.prefix}-oracle9-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.oracle9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "oracle9_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_oracle9_cis_cnspec
  name                        = "${var.prefix}-oracle9-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.oracle9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Oracle Linux 10 - uncomment when AMI data source is available

# module "oracle10" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_oracle10
#   name                        = "${var.prefix}-oracle10-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.oracle10.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
# }

# module "oracle10_cnspec" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_oracle10_cnspec
#   name                        = "${var.prefix}-oracle10-cnspec-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.oracle10.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
#   user_data                   = base64encode(local.linux_user_data)
#   user_data_replace_on_change = true
# }

# CIS Oracle Linux 10 - uncomment when CIS image is available
# module "oracle10_cis" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_oracle10_cis
#   name                        = "${var.prefix}-oracle10-cis-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.oracle10_cis.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
# }

# module "oracle10_cis_cnspec" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_oracle10_cis_cnspec
#   name                        = "${var.prefix}-oracle10-cis-cnspec-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.oracle10_cis.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
#   user_data                   = base64encode(local.linux_user_data)
#   user_data_replace_on_change = true
# }

// AlmaLinux 10 - uncomment when AMI data source is available

# module "alma10" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_alma10
#   name                        = "${var.prefix}-alma10-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.alma10.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
# }

# module "alma10_cnspec" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_alma10_cnspec
#   name                        = "${var.prefix}-alma10-cnspec-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.alma10.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
#   user_data                   = base64encode(local.linux_user_data)
#   user_data_replace_on_change = true
# }

# CIS AlmaLinux 10 - uncomment when CIS image is available
# module "alma10_cis" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_alma10_cis
#   name                        = "${var.prefix}-alma10-cis-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.alma10_cis.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
# }

# module "alma10_cis_cnspec" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_alma10_cis_cnspec
#   name                        = "${var.prefix}-alma10-cis-cnspec-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.alma10_cis.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
#   user_data                   = base64encode(local.linux_user_data)
#   user_data_replace_on_change = true
# }

// Red Hat Linux 9

module "rhel9" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel9
  name                        = "${var.prefix}-rhel9-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rhel9_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel9_cnspec
  name                        = "${var.prefix}-rhel9-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "rhel9_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel9_cis
  name                        = "${var.prefix}-rhel9-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rhel9_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel9_cis_cnspec
  name                        = "${var.prefix}-rhel9-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}



// Red Hat Linux 8

module "rhel8" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel8
  name                        = "${var.prefix}-rhel8-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel8.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rhel8_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel8_cnspec
  name                        = "${var.prefix}-rhel8-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel8.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "rhel8_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel8_cis
  name                        = "${var.prefix}-rhel8-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel8_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rhel8_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rhel8_cis_cnspec
  name                        = "${var.prefix}-rhel8-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rhel8_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// NGINX on RHEL 9 CIS

module "nginx_rhel9_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_nginx_rhel9_cis
  name                        = "${var.prefix}-nginx-rhel9-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.nginx_rhel9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "nginx_rhel9_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_nginx_rhel9_cis_cnspec
  name                        = "${var.prefix}-nginx-rhel9-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.nginx_rhel9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// NGINX on Windows 2019

module "nginx_win2019_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_nginx_win2019_cnspec
  name                        = "${var.prefix}-nginx-win2019-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.nginx_win2019.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data_cnspec)
  user_data_replace_on_change = true
}
// Ubuntu1804
module "ubuntu1804" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu1804
  name                        = "${var.prefix}-ubuntu1804-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu1804.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}
module "ubuntu1804_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu1804_cnspec
  name                        = "${var.prefix}-ubuntu1804-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu1804.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Ubuntu2004
module "ubuntu2004" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2004
  name                        = "${var.prefix}-ubuntu2004-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2004.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "ubuntu2004_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2004_cnspec
  name                        = "${var.prefix}-ubuntu2004-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2004.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}


// Ubuntu 22.04

module "ubuntu2204" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2204
  name                        = "${var.prefix}-ubuntu2204-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2204.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "ubuntu2204_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2204_cnspec
  name                        = "${var.prefix}-ubuntu2204-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2204.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "ubuntu2204_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2204_cis
  name                        = "${var.prefix}-ubuntu2204-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2204_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "ubuntu2204_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2204_cis_cnspec
  name                        = "${var.prefix}-ubuntu2204-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2204_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Ubuntu 22.04 CIS arm64
module "ubuntu2204_cis_arm" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2204_cis_arm
  name                        = "${var.prefix}-ubuntu2204-cis-arm-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2204_cis_arm64.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "ubuntu2204_cis_cnspec_arm" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2204_cis_cnspec_arm
  name                        = "${var.prefix}-ubuntu2204-cis-cnspec-arm-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2204_cis_arm64.id
  instance_type               = var.linux_instance_type_arm64
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

# Ubuntu 24.04 ARM
module "ubuntu2404_arm64_cnspec_arm" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2404_arm64_cnspec_arm
  name                        = "${var.prefix}-ubuntu2404-cnspec-arm-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2404_arm64.id
  instance_type               = var.linux_instance_type_arm64_new
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

# Ubuntu 24.04 amd64
module "ubuntu2404" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_ubuntu2404
  name                        = "${var.prefix}-ubuntu2404-${random_id.instance_id.id}"
  ami                         = data.aws_ami.ubuntu2404.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data_replace_on_change = true
}


// SuSe Enterprise 15

module "suse15" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_suse15
  name                        = "${var.prefix}-suse15-${random_id.instance_id.id}"
  ami                         = data.aws_ami.suse15.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "suse15_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_suse15_cnspec
  name                        = "${var.prefix}-suse15-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.suse15.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "suse15_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_suse15_cis
  name                        = "${var.prefix}-suse15-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.suse15_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "suse15_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_suse15_cis_cnspec
  name                        = "${var.prefix}-suse15-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.suse15_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Rocky 9

module "rocky9" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky9
  name                        = "${var.prefix}-rocky9-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rocky9_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky9_cnspec
  name                        = "${var.prefix}-rocky9-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "rocky9_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky9_cis
  name                        = "${var.prefix}-rocky9-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rocky9_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky9_cis_cnspec
  name                        = "${var.prefix}-rocky9-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky9_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Rocky Linux 10

module "rocky10" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky10
  name                        = "${var.prefix}-rocky10-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky10.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rocky10_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky10_cnspec
  name                        = "${var.prefix}-rocky10-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky10.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

// Rocky Linux 10 ARM64

module "rocky10_arm64" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky10_arm64
  name                        = "${var.prefix}-rocky10-arm64-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky10_arm64.id
  instance_type               = var.linux_instance_type_arm64
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rocky10_arm64_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_rocky10_arm64_cnspec
  name                        = "${var.prefix}-rocky10-arm64-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.rocky10_arm64.id
  instance_type               = var.linux_instance_type_arm64
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

# CIS Rocky Linux 10 - uncomment when CIS image is available
# module "rocky10_cis" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_rocky10_cis
#   name                        = "${var.prefix}-rocky10-cis-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.rocky10_cis.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
# }

# module "rocky10_cis_cnspec" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 5.7.1"
#
#   create                      = var.create_rocky10_cis_cnspec
#   name                        = "${var.prefix}-rocky10-cis-cnspec-${random_id.instance_id.id}"
#   ami                         = data.aws_ami.rocky10_cis.id
#   instance_type               = var.linux_instance_type
#   vpc_security_group_ids      = [module.linux_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   key_name                    = var.aws_key_pair_name
#   associate_public_ip_address = true
#   user_data                   = base64encode(local.linux_user_data)
#   user_data_replace_on_change = true
# }

////////////////////////////////
// Windows Security Groups

module "windows_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${var.prefix}-${random_id.instance_id.id}-windows-sg"
  description = "Security group for testing windows instances"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all from my ip"
      cidr_blocks = "10.10.0.0/16,${local.userIP}"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

# ////////////////////////////////
# // Windows Instances

// Windows 2016

module "windows2016" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2016
  name                        = "${var.prefix}-windows2016-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2016.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
}

module "windows2016_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2016_cnspec
  name                        = "${var.prefix}-windows2016-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2016.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data_cnspec)
  user_data_replace_on_change = true
}

module "windows2016_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2016_cis
  name                        = "${var.prefix}-windows2016-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2016_cis.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
  get_password_data           = true
}

module "windows2016_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2016_cis_cnspec
  name                        = "${var.prefix}-windows2016-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2016_cis.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data_cnspec)
  user_data_replace_on_change = true
  get_password_data           = true
}

// Windows 2019

module "windows2019" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2019
  name                        = "${var.prefix}-windows2019-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2019.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
}

module "windows2019_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2019_cnspec
  name                        = "${var.prefix}-windows2019-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2019.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data_cnspec)
  user_data_replace_on_change = true
}

module "windows2019_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2019_cis
  name                        = "${var.prefix}-windows2019-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2019_cis.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
  get_password_data           = true
}

module "windows2019_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2019_cis_cnspec
  name                        = "${var.prefix}-windows2019-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2019_cis.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data_cnspec)
  user_data_replace_on_change = true
  get_password_data           = true
}

// Windows 2022

module "windows2022" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2022
  name                        = "${var.prefix}-windows2022-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
}

module "windows2022_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2022_cnspec
  name                        = "${var.prefix}-windows2022-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data_cnspec)
  user_data_replace_on_change = true
}

module "windows2022_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2022_cis
  name                        = "${var.prefix}-windows2022-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022_cis.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
  get_password_data           = true
}

module "windows2022_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2022_cis_cnspec
  name                        = "${var.prefix}-windows2022-cis-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022_cis.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data_cnspec)
  user_data_replace_on_change = true
  get_password_data           = true
}

module "windows2022_german" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2022_german
  name                        = "${var.prefix}-windows2022-german-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022_german.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
}

module "windows2022_italian" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_windows2022_italian
  name                        = "${var.prefix}-windows2022-italian-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022_italian.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
}

////////////////////////////////
// Private AMI Instances

module "private_ami" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_private_ami
  name                        = "${var.prefix}-${var.private_ami_name}-${random_id.instance_id.id}"
  ami                         = data.aws_ami.private_ami.id
  instance_type               = var.private_ami_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "private_ami_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.7.1"

  create                      = var.create_private_ami_cnspec
  name                        = "${var.prefix}-${var.private_ami_name}-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.private_ami.id
  instance_type               = var.private_ami_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}
