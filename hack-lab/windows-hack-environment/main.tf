################################################################################
# Data & Locals
################################################################################

data "aws_availability_zones" "available" {}

#data "aws_caller_identity" "current" {}

locals {
  name            = "${random_string.suffix.result}-${var.demo_name}-mondoo-hacklab"
  default_tags = {
    Name       = local.name
    GitHubRepo = "windows-hack-environment"
    GitHubOrg  = "Lunalectric"
    Terraform  = true
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  #upper   = false
}

################################################################################
# VPC Configuration
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.4.0"

  name                 = "${local.name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  tags = merge(
    local.default_tags, {
      "Name"                                = "${local.name}-vpc"
      "${local.name}" = "shared"
    },
  )

  public_subnet_tags = {
    "public/${local.name}" = "shared"
  }

  private_subnet_tags = {
    "private/${local.name}" = "shared"
  }
}

################################################################################
# SSM IAM role
################################################################################

resource "aws_iam_instance_profile" "dev-resources-iam-profile" {
  name = "ec2_ssm_profile-${local.name}-${random_string.suffix.result}"
  role = aws_iam_role.dev-resources-iam-role.name
}

resource "aws_iam_role" "dev-resources-iam-role" {
  name        = "SSM-role-${local.name}-${random_string.suffix.result}"
  description = "The SSM role for Mondoo Hacklab"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
  "Effect": "Allow",
  "Principal": {"Service": "ec2.amazonaws.com"},
  "Action": "sts:AssumeRole"
  }
}
  EOF
  tags = merge(
    local.default_tags, {
      "Name" = "${random_string.suffix.result}-mondoo-hacklab"
    },
  )
}

resource "aws_iam_role_policy_attachment" "dev-resources-ssm-policy" {
  role       = aws_iam_role.dev-resources-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
# Windows Security Group
################################################################################

resource "aws_security_group" "windows_access" {
  name_prefix = "${random_string.suffix.result}_windows_access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "10.0.0.0/8",
      "${var.publicIP}"
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.default_tags
}

################################################################################
# Windows Active Directory Instance
################################################################################

data "aws_ami" "windows-ad" {
  most_recent = true
  owners      = ["801119661308"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-2023*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "windows-ad-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.5.0"

  name = "${local.name}-windows-AD"

  ami                         = data.aws_ami.windows-ad.id
  instance_type               = "m5.xlarge"
  key_name                    = var.ssh_key
  get_password_data           = "true"
  iam_instance_profile        = aws_iam_instance_profile.dev-resources-iam-profile.name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.windows_access.id]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  private_ip                  = "10.0.4.10"
  associate_public_ip_address = true
  user_data = <<EOF
<powershell>
Add-WindowsCapability -Online -Name OpenSSH.Server
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
$NewPassword = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
Set-LocalUser -Name Administrator -Password $NewPassword
</powershell>
EOF

  tags = merge(
    local.default_tags, {
      "Name" = "${random_string.suffix.result}-windows-ad-instance"
    },
  )
}

################################################################################
# Windows Exchange Instance
################################################################################

data "aws_ami" "windows-exchange" {
  most_recent = true
  owners      = ["801119661308"]

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "windows-exchange" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.5.0"

  name = "${local.name}-windows-exchange"

  ami                         = data.aws_ami.windows-exchange.id
  instance_type               = "m5.4xlarge"
  key_name                    = var.ssh_key
  iam_instance_profile        = aws_iam_instance_profile.dev-resources-iam-profile.name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.windows_access.id]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  private_ip                  = "10.0.4.11"
  associate_public_ip_address = true
  user_data = <<EOF
<powershell>
Set-Location -Path 'C:\Program Files'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.0.0p1-Beta/OpenSSH-Win64.zip' -OutFile openssh.zip
Expand-Archive 'openssh.zip' -DestinationPath 'C:\Program Files\'
$oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
$newpath = "$oldpath;C:\Program Files\OpenSSH-Win64"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
Set-Location -Path 'C:\Program Files\OpenSSH-Win64'
powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
$NewPassword = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
Set-LocalUser -Name Administrator -Password $NewPassword
netsh advfirewall set allprofiles state off
</powershell>
EOF

  tags = merge(
    local.default_tags, {
      "Name" = "${random_string.suffix.result}-windows-exchange-instance"
    },
  )

  root_block_device = [
    {
      delete_on_termination = true
      volume_type = "gp2"
      volume_size = 200
    },
  ]

  depends_on = [module.windows-ad-instance]
}

################################################################################
# Windows DVWA Instance
################################################################################

data "aws_ami" "windows-dvwa" {
  most_recent = true
  owners      = ["921877552404"]

  filter {
    name   = "name"
    values = ["win2016-dvwa-printnightmare-final-2022*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "windows-dvwa" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.5.0"

  name = "${local.name}-windows-dvwa"

  ami                         = data.aws_ami.windows-dvwa.id #"ami-0937b231c090e893d"
  instance_type               = "t3.medium"
  key_name                    = var.ssh_key
  iam_instance_profile        = aws_iam_instance_profile.dev-resources-iam-profile.name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.windows_access.id]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  user_data = <<EOF
<powershell>
Set-Location -Path 'C:\Program Files'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.0.0p1-Beta/OpenSSH-Win64.zip' -OutFile openssh.zip
Expand-Archive 'openssh.zip' -DestinationPath 'C:\Program Files\'
$oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
$newpath = "$oldpath;C:\Program Files\OpenSSH-Win64"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
Set-Location -Path 'C:\Program Files\OpenSSH-Win64'
powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
$NewPassword = ConvertTo-SecureString "${var.admin_password}" -AsPlainText -Force
Set-LocalUser -Name Administrator -Password $NewPassword
</powershell>
EOF

  tags = merge(
    local.default_tags, {
      "Name" = "${random_string.suffix.result}-windows-dvwa-instance"
    },
  )

  depends_on = [module.windows-exchange]
}

################################################################################
# Kali Attacker Instance
################################################################################

data "aws_ami" "kali_linux" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["kali-last-snapshot-amd64*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "kali_linux_access" {
  name_prefix = "${random_string.suffix.result}_kali_linux_access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "10.0.0.0/8",
      "${var.publicIP}"
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.default_tags
}

module "kali" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.5.0"

  name = "${local.name}-kali-linux"

  ami                         = data.aws_ami.kali_linux.id
  instance_type               = "t3.medium"
  key_name                    = var.ssh_key
  iam_instance_profile        = aws_iam_instance_profile.dev-resources-iam-profile.name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.kali_linux_access.id]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  user_data                   = templatefile("${path.module}/templates/change-password.tftpl", { pass_string = "${var.admin_password}" })
  associate_public_ip_address = true

  tags = merge(
    local.default_tags, {
      "Name" = "${random_string.suffix.result}-kali-linux-hacker-instance"
    },
  )
}

resource "local_file" "inventory" {
    filename = "./ansible-inventory/inventory.yml"
    depends_on = [module.windows-ad-instance, module.windows-exchange]
    content     = <<EOF
    all:
      vars:
        ansible_user: Administrator
        ansible_password: "${var.admin_password}"
        ansible_connection: ssh
        ansible_port: 22
        ansible_shell_type: powershell
        username: mondoo
        password: mondoo.com
        domain_name: mondoo.hacklab
        man_adcs_winrm_domain: '{{ domain_name }}'
        domain_admin: Administrator
        domain_admin_password: "${var.admin_password}"
        netbios_name: MONDOO
        domain_mode: WinThreshold
        dns_server:
          - 10.0.4.10
          - 8.8.8.8

      hosts:
        dc:
          ansible_host: ${module.windows-ad-instance.public_ip}
        exchange:
          ansible_host: ${module.windows-exchange.public_ip}
        dvwa:
          ansible_host: ${module.windows-dvwa.public_ip}

    EOF
}

################################################################################
# Windows Active Directory run ansible
################################################################################

resource "null_resource" "windows-ad-ansible-run" {
  provisioner "local-exec" {
    working_dir = "./ansible-inventory"
    command = "sleep 60;ansible-playbook -v -i inventory.yml windows-deploy-ad.yml"
  }
  depends_on = [module.windows-ad-instance, resource.local_file.inventory]
}

################################################################################
# Windows Exchange run ansible
################################################################################

resource "null_resource" "windows-exchange-ansible-run" {
  provisioner "local-exec" {
    working_dir = "./ansible-inventory"
    command = "sleep 60;ansible-playbook -v -i inventory.yml windows-exchange.yml"
  }
  depends_on = [module.windows-ad-instance, module.windows-exchange, resource.local_file.inventory, resource.null_resource.windows-ad-ansible-run]
}

################################################################################
# Windows DVWA run ansible
################################################################################

resource "null_resource" "windows-dvwa-ansible-run" {
  provisioner "local-exec" {
    working_dir = "./ansible-inventory"
    command = "sleep 60;ansible-playbook -v -i inventory.yml windows-dvwa.yml"
  }
  depends_on = [module.windows-ad-instance, module.windows-dvwa, resource.local_file.inventory, resource.null_resource.windows-exchange-ansible-run]
}