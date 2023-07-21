# AWS EC2 INSTANCES

This repository contains Terraform code for provisioning AWS EC2 instances for testing cnspec policies. The code creates the following:

- AWS VPC
- EC2 Security group for Linux with all ports open to your ip address
- EC2 Security group for Windows with all ports open to your ip address
- EC2 instances into the provisioned VPC:
  - Amazon Linux 2 and CIS variant
  - Ubuntu 2204 and CIS variant
  - Debian 11, 10 and CIS variant
  - Suse 15 and CIS variant
  - Windows 2022 and CIS variant

### Prereqs

- AWS Account
- Terraform
- Mondoo Platform account
- Mondoo Registration token

## Provision

Example `terraform.tfvars`:

```bash

prefix = "ec2-secops-test"

aws_key_pair_name = "scottford"

publicIP="92.206.212.114/32"

linux_instance_type = "t2.medium"

windows_instance_type = "t2.large"

mondoo_registration_token = "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9...."

create_amazon2 = true

create_windows2022 = true

create_windows2022_cis = true
```

```
terraform init
terraform plan -out tfplan.out
terraform apply tfplan.out
```

