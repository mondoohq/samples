# AWS EC2 INSTANCES

This repository contains Terraform code for provisioning AWS EC2 instances for testing cnspec behind a squid proxy. The code creates the following:

- AWS VPC
- EC2 Security group for Linux with all ports open to your ip address
- 2 EC instances
  - One Debian12 is running the squid proxy (running port 3128)
  - One Debian12 is allowed to ssh in and to communicate to the squid proxy (no direct internet access)

## Prereqs

- AWS Account
- Terraform

## Provision

Example `terraform.tfvars`:

```coffee
prefix = "ec2-secops-test"

aws_key_pair_name = "scottford"

ssh_key = "~/.ssh/ssh-rsa"

publicIP="1.1.1.1/32"

linux_instance_type = "t2.medium"
```

```bash
terraform init
terraform plan -out tfplan.out
terraform apply tfplan.out
```

## Test the squid proxy

```bash
curl -vk --proxy http://<private ip from proxy>:3128 https://google.de
```

Show the proxy connection in the log file

```bash
tail -f /var/log/squid/access.log
```
