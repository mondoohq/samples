# AWS EC2 INSTANCES

This repository contains Terraform code for provisioning AWS EC2 instances for testing cnspec policies. The code creates the following:

- AWS VPC
- EC2 Security group for Linux with all ports open to your ip address
- EC2 Security group for Windows with all ports open to your ip address
- 1 or more EC2 instances into the provisioned VPC

## Prereqs

- AWS Account
- Terraform
- Mondoo Platform account
- Mondoo Registration token

## Supported Platforms

| Platform                     | Description                                                              | Variable                             | Subscription                                                                                                                                                          |
|------------------------------|--------------------------------------------------------------------------|--------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Amazon Linux 2023            | Latest Amazon Linux 2023 image                                           | `create_amazon2023`                  | N/A                                                                                                                                                                   |
| Amazon Linux 2023 cnspec     | Latest Amazon Linux 2023 image with latest cnspec installed              | `create_amazon2023_cnspec`           | N/A                                                                                                                                                                   |
| Amazon Linux 2               | Latest Amazon Linux 2 image                                              | `create_amazon2`                     | N/A                                                                                                                                                                   |
| Amazon Linux 2 cnspec        | Latest Amazon Linux 2 image with latest cnspec installed                 | `create_amazon2_cnspec`              | N/A                                                                                                                                                                   |
| Amazon Linux 2 CIS           | CIS Amazon Linux 2 Benchmark - Level 2                                   | `create_amazon2_cis`                 | [Amazon Marketplace](https://aws.amazon.com/marketplace/pp/prodview-wm36yptaecjnu)                                                                                    |
| Amazon Linux 2 CIS cnspec    | CIS Amazon Linux 2 Benchmark - Level 2 with latest cnspec                | `create_amazon2_cis_cnspec`          | [Amazon Marketplace](https://aws.amazon.com/marketplace/pp/prodview-wm36yptaecjnu)                                                                                    |
| Debian 11                    | Latest Debian 11 image                                                   | `create_debian11`                    | N/A                                                                                                                                                                   |
| Debian 11 cnspec             | Latest Debian 11 image with cnspec                                       | `create_debian11_cnspec`             | N/A                                                                                                                                                                   |
| Debian 11 CIS                | CIS Debian Linux 11 Benchmark - Level 1                                  | `create_debian11_cis`                | [CIS Debian Linux 11 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp?sku=7158qffnkd38liu1mrksgz53n)                                                        |
| Debian 11 CIS cnspec         | CIS Debian Linux 11 Benchmark - Level 1 with latest cnspec               | `create_debian11_cis_cnspec`         | [CIS Debian Linux 11 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp?sku=7158qffnkd38liu1mrksgz53n)                                                        |
| Debian 12 CIS                | CIS Debian Linux 12 Benchmark - Level 1                                  | `create_debian12_cis`                | [CIS Debian Linux 12 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-qx5nmpdvckqgc?applicationId=AWSMPContessa&ref_=beagle&sr=0-3)                |
| Debian 12 CIS cnspec         | CIS Debian Linux 12 Benchmark - Level 1 with latest cnspec               | `create_debian12_cis_cnspec`         | [CIS Debian Linux 12 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-qx5nmpdvckqgc?applicationId=AWSMPContessa&ref_=beagle&sr=0-3)                |
| Oracle 7 CIS                 | CIS Oracle Linux 7 Benchmark - Level 1                                   | `create_oracle7_cis`                 | [CIS Oracle Linux 7 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-pshwm5x5a7wmg?sr=0-24&ref_=beagle&applicationId=AWSMPContessa)                |
| Oracle 7 CIS cnspec          | CIS Oracle Linux 7 Benchmark - Level 1 with latest cnspec                | `create_oracle7_cis_cnspec`          | [CIS Oracle Linux 7 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-pshwm5x5a7wmg?sr=0-24&ref_=beagle&applicationId=AWSMPContessa)                |
| Oracle 8 CIS                 | CIS Oracle Linux 8 Benchmark - Level 1                                   | `create_oracle8_cis`                 | [CIS Oracle Linux 8 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-qohiqfju7iecs?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)                 |
| Oracle 8 CIS cnspec          | CIS Oracle Linux 8 Benchmark - Level 1 with latest cnspec                | `create_oracle8_cis_cnspec`          | [CIS Oracle Linux 8 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-qohiqfju7iecs?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)                 |
| Oracle 9                     | Latest Oracle 9 image                                                    | `create_oracle9`                     |                                                                                                                                                                       |
| Oracle 9 cnspec              | Latest Oracle 9 image with latest cnspec                                 | `create_oracle9_cnspec`              |                                                                                                                                                                       |
| Oracle 9 CIS                 | CIS Oracle Linux 9 Benchmark - Level 1                                   | `create_oracle9_cis`                 | [CIS Oracle Linux 9 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-uvycouobpppp4?sr=0-1&ref_=beagle&applicationId=AWS-EC2-Console)               |
| Oracle 9 CIS cnspec          | CIS Oracle Linux 9 Benchmark - Level 1 with latest cnspec                | `create_oracle9_cis_cnspec`          | [CIS Oracle Linux 9 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-uvycouobpppp4?sr=0-1&ref_=beagle&applicationId=AWS-EC2-Console)               |
| RHEL 8                       | Latest Red Hat Enterprise Linux 8                                        | `create_rhel8`                       |                                                                                                                                                                       |
| RHEL 8 cnspec                | Latest Red Hat Enterprise Linux 8 with latest cnspec                     | `create_rhel8_cnspec`                |                                                                                                                                                                       |
| RHEL 8 CIS                   | CIS Red Hat Enterprise Linux 8 STIG Benchmark                            | `create_rhel8_cis`                   | [CIS Red Hat Enterprise Linux 8 STIG Benchmark](https://aws.amazon.com/marketplace/pp/prodview-ia2nfuoig3jmu?sr=0-3&ref_=beagle&applicationId=AWSMPContessa)          |
| RHEL 8 CIS cnspec            | CIS Red Hat Enterprise Linux 8 STIG Benchmark with latest cnspec         | `create_rhel8_cis_cnspec`            | [CIS Red Hat Enterprise Linux 8 STIG Benchmark](https://aws.amazon.com/marketplace/pp/prodview-ia2nfuoig3jmu?sr=0-3&ref_=beagle&applicationId=AWSMPContessa)          |
| RHEL 9                       | Latest RHEL 9 image                                                      | `create_rhel9`                       |                                                                                                                                                                       |
| RHEL 9 cnspec                | Latest RHEL 9 with latest cnspec                                         | `create_rhel9_cnspec`                |                                                                                                                                                                       |
| RHEL 9 CIS                   | CIS Red Hat Enterprise Linux 9 Level 2                                   | `create_rhel9_cis`                   | [CIS Red Hat Enterprise Linux 9 - Level 2](https://aws.amazon.com/marketplace/pp/prodview-6axx7cl7vguti?sr=0-5&ref_=beagle&applicationId=AWS-EC2-Console)             |
| RHEL 9 CIS cnspec            | CIS Red Hat Enterprise Linux 9 Level 2 with latest cnspec                | `create_rhel9_cis_cnspec`            | [CIS Red Hat Enterprise Linux 9 - Level 2](https://aws.amazon.com/marketplace/pp/prodview-6axx7cl7vguti?sr=0-5&ref_=beagle&applicationId=AWS-EC2-Console)             |
| NGINX on RHEL 9 CIS          | Latest NGINX on RHEL 9 image CIS hardened                                | `create_nginx_rhel9_cis`             |                                                                                                                                                                       |
| NGINX on RHEL 9 CIS cnspec   | Latest NGINX on RHEL 9 image CIS hardened with latest cnspec             | `create_nginx_rhel9_cis_cnspec`      |                                                                                                                                                                       |
| SUSE 15                      | Latest SUSE 15 image                                                     | `create_suse15`                      |                                                                                                                                                                       |
| SUSE 15 cnspec               | Latest SUSE 15 image with latest cnspec                                  | `create_suse15_cnspec`               |                                                                                                                                                                       |
| SUSE 15 CIS                  | CIS SUSE Linux Enterprise 15 Benchmark - Level 1                         | `create_suse15_cis`                  | [CIS SUSE Linux Enterprise 15 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-g5eyen7n5tizm?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)       |
| SUSE 15 CIS cnspec           | CIS SUSE Linux Enterprise 15 Benchmark - Level 1 with latest cnspec      | `create_suse15_cis_cnspec`           | [CIS SUSE Linux Enterprise 15 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-g5eyen7n5tizm?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)       |
| Ubuntu 20.04                 | Latest Ubuntu 20.04                                                      | `create_ubuntu2004`                  |                                                                                                                                                                       |
| Ubuntu 20.04 cnspec          | Latest Ubuntu 20.04 with latest cnspec                                   | `create_ubuntu2004_cnspec`           |                                                                                                                                                                       |
| Ubuntu 20.04 CIS             | CIS Ubuntu Linux 20.04 LTS Benchmark - Level 1 with latest cnspec        | `create_ubuntu2004_cis`              | [CIS Ubuntu Linux 20.04 LTS Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-acrp2dhekgpd4?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)         |
| Ubuntu 20.04 CIS cnspec      | CIS Ubuntu Linux 20.04 LTS Benchmark - Level 1 with latest cnspec        | `create_ubuntu2004_cis_cnspec`       | [CIS Ubuntu Linux 20.04 LTS Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-acrp2dhekgpd4?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)         |
| Ubuntu 22.04                 | Latest Ubuntu 22.04                                                      | `create_ubuntu2204`                  |                                                                                                                                                                       |
| Ubuntu 22.04 cnspec          | Latest Ubuntu 22.04 with latest cnspec                                   | `create_ubuntu2204_cnspec`           |                                                                                                                                                                       |
| Ubuntu 22.04 CIS             | CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1                           | `create_ubuntu2204_cis`              | [CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-7afxz7ijttzk4?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)         |
| Ubuntu 22.04 CIS cnspec      | CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1 with latest cnspec        | `create_ubuntu2204_cis_cnspec`       | [CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-7afxz7ijttzk4?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)         |
| Ubuntu 22.04 CIS ARM         | CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1 on ARM                    | `create_ubuntu2204_cis_arm`          | [CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1 (ARM)](https://aws.amazon.com/marketplace/pp/prodview-r547agtl65wsu?sr=0-1&ref_=beagle&applicationId=AWS-EC2-Console) |
| Ubuntu 22.04 CIS ARM cnspec  | CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1 with latest cnspec on ARM | `create_ubuntu2204_cis_cnspec_arm`   | [CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1 (ARM)](https://aws.amazon.com/marketplace/pp/prodview-r547agtl65wsu?sr=0-1&ref_=beagle&applicationId=AWS-EC2-Console) |
| Ubuntu 24.04 ARM cnspec      | Latest Ubuntu Linux 24.04 with latest cnspec on ARM                      | `create_ubuntu2404_arm64_cnspec_arm` | [Ubuntu Linux 24.04 LTS (ARM)](https://aws.amazon.com/marketplace/pp/prodview-ppkztkiaeuede?applicationId=AWS-EC2-Console&ref_=beagle&sr=0-3)                         |
| Ubuntu 24.04                 | Latest Ubuntu Linux 24.04 based on amd64                                 | `create_ubuntu2404`                  | [Ubuntu Linux 24.04 LTS](https://aws.amazon.com/marketplace/pp/prodview-s4zvkzmlirbga?sr=0-8&ref_=beagle&applicationId=AWSMPContessa)                                 |
| Rocky 9                      | Latest Rocky 9 image                                                     | `create_rocky9`                      |                                                                                                                                                                       |
| Rocky 9 cnspec               | Latest Rocky 9 image with latest cnspec                                  | `create_rocky9_cnspec`               |                                                                                                                                                                       |
| Rocky 9 CIS                  | CIS Rocky Linux 9 Benchmark - Level 1                                    | `create_rocky9_cis`                  | [CIS Rocky Linux 9 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-4dof2bylegr46?sr=0-39&ref_=beagle&applicationId=AWSMPContessa)                 |
| Rocky 9 CIS cnspec           | CIS Rocky Linux 9 Benchmark - Level 1 with latest cnspec                 | `create_rocky9_cis_cnspec`           | [CIS Rocky Linux 9 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-4dof2bylegr46?sr=0-39&ref_=beagle&applicationId=AWSMPContessa)                 |
| Windows 2016                 | Latest Windows 2016 Server                                               | `create_windows2016`                 | N/A                                                                                                                                                                   |
| Windows 2016 cnspec          | Latest Windows 2016 Server with latest cnspec                            | `create_windows2016_cnspec`          | N/A                                                                                                                                                                   |
| Windows 2016 CIS             | CIS Microsoft Windows Server 2016 Benchmark - Level 2                    | `create_windows2016_cis`             | [CIS Microsoft Windows Server 2016 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-mytoha3qyuk7y?sr=0-9&ref_=beagle&applicationId=AWSMPContessa)  |
| Windows 2016 CIS cnspec      | CIS Microsoft Windows Server 2016 Benchmark - Level 2 with latest cnspec | `create_windows2016_cis_cnspec`      | [CIS Microsoft Windows Server 2016 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-mytoha3qyuk7y?sr=0-9&ref_=beagle&applicationId=AWSMPContessa)  |
| Windows 2019                 | Latest Windows 2019 Server                                               | `create_windows2019`                 | N/A                                                                                                                                                                   |
| Windows 2019 cnspec          | Latest Windows 2019 Server with latest cnspec                            | `create_windows2019_cnspec`          | N/A                                                                                                                                                                   |
| Windows 2019 CIS             | CIS Microsoft Windows Server 2019 Benchmark - Level 2                    | `create_windows2019_cis`             | [CIS Microsoft Windows Server 2019 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-zgh6fzj3hbf7o?sr=0-11&ref_=beagle&applicationId=AWSMPContessa) |
| Windows 2019 CIS cnspec      | CIS Microsoft Windows Server 2019 Benchmark - Level 2 with latest cnspec | `create_windows2019_cis_cnspec`      | [CIS Microsoft Windows Server 2019 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-zgh6fzj3hbf7o?sr=0-11&ref_=beagle&applicationId=AWSMPContessa) |
| Windows 2022                 | Latest Windows 2022 Server                                               | `create_windows2022`                 | N/A                                                                                                                                                                   |
| Windows 2022 cnspec          | Latest Windows 2022 Server with latest cnspec                            | `create_windows2022_cnspec`          | N/A                                                                                                                                                                   |
| Windows 2022 CIS             | CIS Microsoft Windows Server 2022 Benchmark - Level 2                    | `create_windows2022_cis`             | [CIS Microsoft Windows Server 2022 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-lhbxwzmvsawbw?sr=0-19&ref_=beagle&applicationId=AWSMPContessa) |
| Windows 2022 CIS cnspec      | CIS Microsoft Windows Server 2022 Benchmark - Level 2 with latest cnspec | `create_windows2022_cis_cnspec`      | [CIS Microsoft Windows Server 2022 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-lhbxwzmvsawbw?sr=0-19&ref_=beagle&applicationId=AWSMPContessa) |
| Windows 2022 German          | Latest Windows 2022 Server German                                        | `create_windows2022_german`          | N/A                                                                                                                                                                   |
| Windows 2022 Italian         | Latest Windows 2022 Server Italian                                       | `create_windows2022_italian`         | N/A                                                                                                                                                                   |
| NGINX on Windows 2019 Server | NGINX on Windows 2019 Server                                             | `create_nginx_win2019_cnspec`        | N/A                                                                                                                                                                   |

## Provision

Example `terraform.tfvars`:

```bash

prefix = "ec2-secops-test"

aws_key_pair_name = "scottford"

ssh_key = "~/.ssh/ssh-rsa"

publicIP="1.1.1.1/32"

linux_instance_type = "t2.medium"

windows_instance_type = "t2.large"

mondoo_registration_token = "eyJhbGciOiJFUzM4NCIsInR5cCI6IkpXVCJ9...."

create_amazon2 = true

create_windows2022 = true

create_windows2022_cnspec = true

create_windows2022_cis = true

create_windows2022_cis_cnspec = true
```

```
terraform init
terraform plan -out tfplan.out
terraform apply tfplan.out
```

## Find AWS AMI

```bash
aws ec2 describe-images --region us-east-2 --filters "Name=architecture,Values=x86_64" "Name=name,Values=Windows_Server-2019-English-Full-Base*" "Name=root-device-type,Values=ebs" --output table --query 'Images[*].{Owner:OwnerId,CreationDate:CreationDate,Name:Name,ID:ImageId,Release:Release}'
```

## Another example

```bash
aws ec2 describe-images --region us-east-2 --filters "Name=architecture,Values=arm64" "Name=name,Values=*ubuntu-noble-24.04-arm64-server*" "Name=root-device-type,Values=ebs" "Name=owner-id,Values='679593333241'" --output table --query 'Images[*].{Owner:OwnerId,CreationDate:CreationDate,Name:Name,ID:ImageId,Release:Release}'
```