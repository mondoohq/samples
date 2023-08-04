resource "random_id" "instance_id" {
  byte_length = 4
}

locals {
  linux_user_data = <<-EOT
    #!/bin/bash
    bash -c "$(curl -sSL https://install.mondoo.com/sh)"
    cnspec login --token ${var.mondoo_registration_token} --config /etc/opt/mondoo/mondoo.yml
    cnspec scan local --config /etc/opt/mondoo/mondoo.yml --asset-name $(uname -r)
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
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    iex ((New-Object System.Net.WebClient).DownloadString('https://install.mondoo.com/ps1'));
    Install-Mondoo;
    cnspec scan local --config C:\ProgramData\Mondoo\mondoo.yml --asset-name $(Get-ComputerInfo | Select-Object OSName, OSVersion, OsHardwareAbstractionLayer)
    </powershell>
  EOT
}

////////////////////////////////
// VPC Configuration

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1.0"

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
  version = "~> 4.3"

  name        = "${var.prefix}-${random_id.instance_id.id}-linux-sg"
  description = "Security group for linux instances"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all from my ip"
      cidr_blocks = "10.10.0.0/16,${var.publicIP}"
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

module "amazon2023" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_amazon2023
  name                        = "${var.prefix}-amazon2023"
  ami                         = data.aws_ami.amazon2023.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "amazon2023_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_amazon2023_cnspec
  name                        = "${var.prefix}-amazon2023-cnspec"
  ami                         = data.aws_ami.amazon2023.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "amazon2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_amazon2
  name                        = "${var.prefix}-amazon2"
  ami                         = data.aws_ami.amazon2.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "amazon2_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_amazon2_cnspec
  name                        = "${var.prefix}-amazon2-cnspec"
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
  version = "~> 5.2.1"

  create                      = var.create_amazon2_cis
  name                        = "${var.prefix}-amazon2-cis"
  ami                         = data.aws_ami.amazon2_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "amazon2_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_amazon2_cis_cnspec
  name                        = "${var.prefix}-amazon2-cis-cnspec"
  ami                         = data.aws_ami.amazon2_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "debian11" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_debian11
  name                        = "${var.prefix}-debian11"
  ami                         = data.aws_ami.debian11.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian11_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_debian11
  name                        = "${var.prefix}-debian11-cnspec"
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
  version = "~> 5.2.1"

  create                      = var.create_debian11_cis
  name                        = "${var.prefix}-debian11-cis"
  ami                         = data.aws_ami.debian11_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian11_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_debian11_cis_cnspec
  name                        = "${var.prefix}-debian11-cis-cnspec"
  ami                         = data.aws_ami.debian11_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "debian12" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_debian12
  name                        = "${var.prefix}-debian12"
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "debian12_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_debian12_cnspec
  name                        = "${var.prefix}-debian12"
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "oracle8" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_oracle8
  name                        = "${var.prefix}-oracle8"
  ami                         = data.aws_ami.oracle8.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "oracle8_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_oracle8_cnspec
  name                        = "${var.prefix}-oracle8-cnspec"
  ami                         = data.aws_ami.oracle8.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "oracle8_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_oracle8_cis
  name                        = "${var.prefix}-oracle8-cis"
  ami                         = data.aws_ami.oracle8_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "oracle8_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_oracle8_cis_cnspec
  name                        = "${var.prefix}-oracle8-cis-cnspec"
  ami                         = data.aws_ami.oracle8_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "rhel9" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"
  
  create                      = var.create_rhel9
  name                        = "${var.prefix}-rhel9"
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rhel9_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"
  
  create                      = var.create_rhel9
  name                        = "${var.prefix}-rhel9-cnspec"
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "rhel8" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"
  
  create                      = var.create_rhel8
  name                        = "${var.prefix}-rhel8"
  ami                         = data.aws_ami.rhel8.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rhel8_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"
  
  create                      = var.create_rhel8_cnspec
  name                        = "${var.prefix}-rhel8-cnspec"
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
  version = "~> 5.2.1"
  
  create                      = var.create_rhel8_cis
  name                        = "${var.prefix}-rhel8-cis"
  ami                         = data.aws_ami.rhel8_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "rhel8_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"
  
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

module "ubuntu2204" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_ubuntu2204
  name                        = "${var.prefix}-ubuntu2204"
  ami                         = data.aws_ami.ubuntu2204.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "ubuntu2204_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_ubuntu2204_cnspec
  name                        = "${var.prefix}-ubuntu2204-cnspec"
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
  version = "~> 5.2.1"

  create                      = var.create_ubuntu2204_cis
  name                        = "${var.prefix}-ubuntu2204-cis"
  ami                         = data.aws_ami.ubuntu2204_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "ubuntu2204_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_ubuntu2204_cis_cnspec
  name                        = "${var.prefix}-ubuntu2204-cis-cnspec"
  ami                         = data.aws_ami.ubuntu2204_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

module "suse15" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

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
  version = "~> 5.2.1"

  create                      = var.create_suse15_cnspec
  name                        = "${var.prefix}-suse15-${random_id.instance_id.id}"
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
  version = "~> 5.2.1"

  create                      = var.create_suse15_cis
  name                        = "${var.prefix}-suse15-cis"
  ami                         = data.aws_ami.suse15_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "suse15_cis_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_suse15_cis_cnspec
  name                        = "${var.prefix}-suse15-cis-cnspec"
  ami                         = data.aws_ami.suse15_cis.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.linux_user_data)
  user_data_replace_on_change = true
}

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
      cidr_blocks = "10.10.0.0/16,${var.publicIP}"
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

module "windows2022" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_windows2022
  name                        = "${var.prefix}-windows2022-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
}

module "windows2022_cnspec" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_windows2022
  name                        = "${var.prefix}-windows2022-cnspec-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data                   = base64encode(local.windows_user_data)
  user_data_replace_on_change = true
}

module "windows2022_cis" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  create                      = var.create_windows2022_cis
  name                        = "${var.prefix}-windows2022-cis-${random_id.instance_id.id}"
  ami                         = data.aws_ami.winserver2022_cis.id
  instance_type               = var.windows_instance_type
  vpc_security_group_ids      = [module.windows_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  associate_public_ip_address = true
  user_data = <<EOF
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
Install-Mondoo;
cnspec scan local --config C:\ProgramData\Mondoo\mondoo.yml --asset-name $(Get-ComputerInfo | Select-Object OSName, OSVersion, OsHardwareAbstractionLayer)
</powershell>
EOF
  user_data_replace_on_change = true
}
