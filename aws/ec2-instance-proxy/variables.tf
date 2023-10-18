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

variable "publicIP" {
  description = "Your home PublicIP to configure access to ec2 instances"
}
