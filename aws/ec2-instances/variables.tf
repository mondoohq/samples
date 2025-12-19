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

variable "linux_instance_type_arm64" {
  default = "t4g.medium"
}

variable "linux_instance_type_arm64_new" {
  default = "m6g.medium"
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

variable "create_ubuntu2204_cis_arm" {
  default = false
}

variable "create_ubuntu2204_cis_cnspec_arm" {
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

variable "create_rhel9_cis" {
  default = false
}

variable "create_rhel9_cis_cnspec" {
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

variable "create_nginx_rhel9_cis" {
  default = false
}

variable "create_nginx_rhel9_cis_cnspec" {
  default = false
}

variable "create_debian10" {
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

variable "create_debian12_cis" {
  default = false
}

variable "create_debian12_cis_cnspec" {
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

variable "create_oracle8_cis" {
  default = false
}

variable "create_oracle8_cis_cnspec" {
  default = false
}

variable "create_oracle9" {
  default = false
}

variable "create_oracle9_cnspec" {
  default = false
}

variable "create_oracle9_cis" {
  default = false
}

variable "create_oracle9_cis_cnspec" {
  default = false
}

// Oracle Linux 10
variable "create_oracle10" {
  default = false
}

variable "create_oracle10_cnspec" {
  default = false
}

# CIS Oracle Linux 10 - uncomment when CIS image is available
# variable "create_oracle10_cis" {
#   default = false
# }

# variable "create_oracle10_cis_cnspec" {
#   default = false
# }

// AlmaLinux 10
variable "create_alma10" {
  default = false
}

variable "create_alma10_cnspec" {
  default = false
}

# CIS AlmaLinux 10 - uncomment when CIS image is available
# variable "create_alma10_cis" {
#   default = false
# }

# variable "create_alma10_cis_cnspec" {
#   default = false
# }

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

variable "create_windows2022_german" {
  default = false
}

variable "create_windows2022_italian" {
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

variable "create_nginx_win2019_cnspec" {
  default = false
}

variable "create_ubuntu2404_arm64_cnspec_arm" {
  default = false
}

variable "create_ubuntu2404" {
  default = false
}

variable "windows_admin_password" {
  default = "MondooSPM1!"
}

variable "publicIP" {
  description = "Your home PublicIP to configure access to ec2 instances"

  # usually automatically pulled by data "http" "clientip" resource
  default = ""
}

////////////////////////////////
// Private AMI Settings

variable "private_ami_id" {
  description = "Private AMI ID to use for creating instances"
  type        = string
  default     = ""
}

variable "private_ami_owner" {
  description = "Owner account ID of the private AMI"
  type        = string
  default     = ""
}

variable "private_ami_name" {
  description = "Name identifier for the private AMI instance (will be used in resource naming)"
  type        = string
  default     = "private"
}

variable "private_ami_ssh_user" {
  description = "SSH user for the private AMI instances"
  type        = string
  default     = "ec2-user"
}

variable "private_ami_instance_type" {
  description = "Instance type for private AMI instances"
  type        = string
  default     = "t2.micro"
}

variable "create_private_ami" {
  description = "Whether to create an instance from the private AMI"
  type        = bool
  default     = false
}

variable "create_private_ami_cnspec" {
  description = "Whether to create an instance from the private AMI with cnspec"
  type        = bool
  default     = false
}
