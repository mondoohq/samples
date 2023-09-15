////////////////////////////////
// AWS Credentials

variable "aws_profile" {
  default = "default"
}

variable "region" {
  default = "us-east-1"
}

////////////////////////////////
// Global Settings

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "mondoo"
}

variable "default_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "Test"
  }
}

variable "mondoo_registration_token" {
  description = "cnspec registration key"
  type        = string
  default     = ""
}

variable "ssh_key" {
  description = "ssh rsa key to decrypt windows password"
  type        = string
  default     = ""
}

////////////////////////////////
// VPC Settings

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type        = bool
  default     = true
}

////////////////////////////////
// EC2 Settings

variable "aws_key_pair_name" {}

variable "linux_instance_type" {
  default = "t2.micro"
}

variable "windows_instance_type" {
  default = "t2.micro"
}

variable "create_amazon2" {
  default = false
}

variable "create_amazon2_cnspec" {
  default = false
}

variable "create_amazon2_cis" {
  default = false
}

variable "create_amazon2_cis_cnspec" {
  default = false
}

variable "create_amazon2023" {
  default = false
}

variable "create_amazon2023_cnspec" {
  default = false
}

variable "create_ubuntu2204" {
  default = false
}

variable "create_ubuntu2204_cnspec" {
  default = false
}

variable "create_ubuntu2204_cis" {
  default = false
}

variable "create_ubuntu2204_cis_cnspec" {
  default = false
}

variable "create_ubuntu2004" {
  default = false
}

variable "create_ubuntu2004_cnspec" {
  default = false
}

variable "create_ubuntu2004_cis" {
  default = false
}

variable "create_ubuntu2004_cis_cnspec" {
  default = false
}

variable "create_ubuntu1804" {
  default = false
}

variable "create_ubuntu1804_cnspec" {
  default = false
}

variable "create_ubuntu1604" {
  default = false
}

variable "create_ubuntu1604_cnspec" {
  default = false
}

variable "create_rhel9" {
  default = false
}

variable "create_rhel9_cnspec" {
  default = false
}

variable "create_rhel8" {
  default = false
}

variable "create_rhel8_cnspec" {
  default = false
}

variable "create_rhel8_cis" {
  default = false
}

variable "create_rhel8_cis_cnspec" {
  default = false
}

variable "create_debian10" {
  default = false
}

variable "create_debian10_cnspec" {
  default = false
}

variable "create_debian10_cis" {
  default = false
}

variable "create_debian10_cis_cnspec" {
  default = false
}

variable "create_debian11" {
  default = false
}

variable "create_debian11_cnspec" {
  default = false
}

variable "create_debian11_cis" {
  default = false
}

variable "create_debian11_cis_cnspec" {
  default = false
}

variable "create_debian12" {
  default = false
}

variable "create_debian12_cnspec" {
  default = false
}

variable "create_suse15" {
  default = false
}

variable "create_suse15_cnspec" {
  default = false
}

variable "create_suse15_cis" {
  default = false
}

variable "create_suse15_cis_cnspec" {
  default = false
}

variable "create_oracle7" {
  default = false
}

variable "create_oracle7_cnspec" {
  default = false
}

variable "create_oracle7_cis" {
  default = false
}

variable "create_oracle7_cis_cnspec" {
  default = false
}

variable "create_oracle8" {
  default = false
}

variable "create_oracle8_cnspec" {
  default = false
}

variable "create_oracle8_cis" {
  default = false
}

variable "create_oracle8_cis_cnspec" {
  default = false
}

variable "create_rocky9" {
  default = false
}

variable "create_rocky9_cnspec" {
  default = false
}

variable "create_rocky9_cis" {
  default = false
}

variable "create_rocky9_cis_cnspec" {
  default = false
}

variable "create_windows2022" {
  default = false
}

variable "create_windows2022_cnspec" {
  default = false
}

variable "create_windows2022_cis" {
  default = false
}

variable "create_windows2022_cis_cnspec" {
  default = false
}

variable "create_windows2019" {
  default = false
}

variable "create_windows2019_cis" {
  default = false
}

variable "create_windows2019_cnspec" {
  default = false
}

variable "create_windows2019_cis_cnspec" {
  default = false
}

variable "create_windows2016" {
  default = false
}

variable "create_windows2016_cis" {
  default = false
}

variable "create_windows2016_cnspec" {
  default = false
}

variable "create_windows2016_cis_cnspec" {
  default = false
}

variable "windows_admin_password" {
  default = "MondooSPM1!"
}

variable "publicIP" {
  description = "Your home PublicIP to configure access to ec2 instances"
}
