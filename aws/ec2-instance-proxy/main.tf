resource "random_id" "instance_id" {
  byte_length = 4
}

locals {
  linux_proxy_data = <<-EOT
    #!/bin/bash
    sudo apt update
    sudo apt install -y iptables curl squid dnsutils
    sudo tee /etc/squid/squid.conf <<EOL
    acl localnet src 0.0.0.1-0.255.255.255	# RFC 1122 "this" network (LAN)
    acl localnet src 10.0.0.0/8		# RFC 1918 local private network (LAN)
    acl SSL_ports port 443
    acl Safe_ports port 80		# http
    acl Safe_ports port 443		# https
    http_access deny !Safe_ports
    http_access deny CONNECT !SSL_ports
    http_access allow localhost manager
    http_access deny manager
    http_access allow localnet
    http_access deny all
    http_port 3128
    coredump_dir /var/spool/squid
    max_filedescriptors 4096
    EOL

    sudo systemctl restart squid
    sudo systemctl enable squid 
  EOT

  linux_data = <<-EOT
    #!/bin/bash
    sudo apt update
    sudo apt install -y iptables curl dnsutils
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
    sudo iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
    sudo iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT
    sudo iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
    sudo iptables -A OUTPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
    sudo iptables -A INPUT  -p udp --sport 53 -m state --state ESTABLISHED     -j ACCEPT
    sudo iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
    sudo iptables -A INPUT  -p tcp --sport 53 -m state --state ESTABLISHED     -j ACCEPT
    sudo iptables -P OUTPUT DROP
    sudo iptables -P INPUT DROP
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
      cidr_blocks = "10.0.0.0/8,${var.publicIP}"
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

// Debian 12 squid proxy

module "debian12_proxy" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  name                        = "${var.prefix}-debian12-proxy-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  user_data                   = base64encode(local.linux_proxy_data)
  user_data_replace_on_change = true
  associate_public_ip_address = true
}

// Debian 12

module "debian12" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"

  name                        = "${var.prefix}-debian12-${random_id.instance_id.id}"
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.linux_instance_type
  vpc_security_group_ids      = [module.linux_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.aws_key_pair_name
  user_data                   = base64encode(local.linux_data)
  user_data_replace_on_change = true
  associate_public_ip_address = true
}
