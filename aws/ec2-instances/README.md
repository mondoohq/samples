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

| Platform                  | Description                                                              | Variable                        | Subscription                                                                                                                                                          |
|---------------------------|--------------------------------------------------------------------------|---------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Amazon Linux 2023         | Latest Amazon Linux 2023 image                                           | `create_amazon2023`             | N/A                                                                                                                                                                   |
| Amazon Linux 2023 cnspec  | Latest Amazon Linux 2023 image with latest cnspec installed              | `create_amazon2023_cnspec`      | N/A                                                                                                                                                                   |
| Amazon Linux 2            | Latest Amazon Linux 2 image                                              | `create_amazon2`                | N/A                                                                                                                                                                   |
| Amazon Linux 2 cnspec     | Latest Amazon Linux 2 image with latest cnspec installed                 | `create_amazon2_cnspec`         | N/A                                                                                                                                                                   |
| Amazon Linux 2 CIS        | CIS Amazon Linux 2 Benchmark - Level 2                                   | `create_amazon2_cis`            | [Amazon Marketplace](https://aws.amazon.com/marketplace/pp/prodview-wm36yptaecjnu)                                                                                    |
| Amazon Linux 2 CIS cnspec | CIS Amazon Linux 2 Benchmark - Level 2 with latest cnspec                | `create_amazon2_cis_cnspec`     | [Amazon Marketplace](https://aws.amazon.com/marketplace/pp/prodview-wm36yptaecjnu)                                                                                    |
| Debian 10 CIS cnspec      | CIS Debian Linux 10 Benchmark - Level 1 with latest cnspec               | `create_debian10_cis_cnspec`    | [CIS Debian Linux 10 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-eftuxfk322rry?sr=0-1&ref_=beagle&applicationId=AWS-EC2-Console)                                                        |
| Debian 11                 | Latest Debian 11 image                                                   | `create_debian11`               | N/A                                                                                                                                                                   |
| Debian 11 cnspec          | Latest Debian 11 image with cnspec                                       | `create_debian11_cnspec`        | N/A                                                                                                                                                                   |
| Debian 11 CIS             | CIS Debian Linux 11 Benchmark - Level 1                                  | `create_debian11_cis`           | [CIS Debian Linux 11 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp?sku=7158qffnkd38liu1mrksgz53n)                                                        |
| Debian 11 CIS cnspec      | CIS Debian Linux 11 Benchmark - Level 1 with latest cnspec               | `create_debian11_cis_cnspec`    | [CIS Debian Linux 11 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp?sku=7158qffnkd38liu1mrksgz53n)                                                        |
| Oracle 7                  | Latest Oracle 7 image                                                    | `create_oracle7`                |                                                                                                                                                                       |
| Oracle 7 cnspec           | Latest Oracle 7 image with latest cnspec                                 | `create_oracle7_cnspec`         |                                                                                                                                                                       |
| Oracle 7 CIS              | CIS Oracle Linux 7 Benchmark - Level 1                                   | `create_oracle7_cis`            | [CIS Oracle Linux 7 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-pshwm5x5a7wmg?sr=0-24&ref_=beagle&applicationId=AWSMPContessa)                |
| Oracle 7 CIS cnspec       | CIS Oracle Linux 7 Benchmark - Level 1 with latest cnspec                | `create_oracle7_cis_cnspec`     | [CIS Oracle Linux 7 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-pshwm5x5a7wmg?sr=0-24&ref_=beagle&applicationId=AWSMPContessa)                |
| Oracle 8                  | Latest Oracle 8 image                                                    | `create_oracle8`                |                                                                                                                                                                       |
| Oracle 8 cnspec           | Latest Oracle 8 image with latest cnspec                                 | `create_oracle8_cnspec`         |                                                                                                                                                                       |
| Oracle 8 CIS              | CIS Oracle Linux 8 Benchmark - Level 1                                   | `create_oracle8_cis`            | [CIS Oracle Linux 8 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-qohiqfju7iecs?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)                 |
| Oracle 8 CIS cnspec       | CIS Oracle Linux 8 Benchmark - Level 1 with latest cnspec                | `create_oracle8_cis_cnspec`     | [CIS Oracle Linux 8 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-qohiqfju7iecs?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)                 |
| RHEL 8                    | Latest RedHat Enterprise Linux 8                                         | `create_rhel8`                  |                                                                                                                                                                       |
| RHEL 8 cnspec             | Latest RedHat Enterprise Linux 8 with latest cnspec                      | `create_rhel8_cnspec`           |                                                                                                                                                                       |
| RHEL 8 CIS                | CIS Red Hat Enterprise Linux 8 STIG Benchmark                            | `create_rhel8_cis`              | [CIS Red Hat Enterprise Linux 8 STIG Benchmark](https://aws.amazon.com/marketplace/pp/prodview-ia2nfuoig3jmu?sr=0-3&ref_=beagle&applicationId=AWSMPContessa)          |
| RHEL 8 CIS cnspec         | CIS Red Hat Enterprise Linux 8 STIG Benchmark with latest cnspec         | `create_rhel8_cis_cnspec`       | [CIS Red Hat Enterprise Linux 8 STIG Benchmark](https://aws.amazon.com/marketplace/pp/prodview-ia2nfuoig3jmu?sr=0-3&ref_=beagle&applicationId=AWSMPContessa)          |
| RHEL 9                    | Latest RHEL 9 image                                                      | `create_rhel9`                  |                                                                                                                                                                       |
| RHEL 9 cnspec             | Latest RHEL 9 with latest cnspec                                         | `create_rhel9_cnspec`           |                                                                                                                                                                       |
| SUSE 15                   | Latest SUSE 15 image                                                     | `create_suse15`                 |                                                                                                                                                                       |
| SUSE 15 cnspec            | Latest SUSE 15 image with latest cnspec                                  | `create_suse15_cnspec`          |                                                                                                                                                                       |
| SUSE 15 CIS               | CIS SUSE Linux Enterprise 15 Benchmark - Level 1                         | `create_suse15_cis`             | [CIS SUSE Linux Enterprise 15 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-g5eyen7n5tizm?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)       |
| SUSE 15 CIS cnspec        | CIS SUSE Linux Enterprise 15 Benchmark - Level 1 with latest cnspec      | `create_suse15_cis_cnspec`      | [CIS SUSE Linux Enterprise 15 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-g5eyen7n5tizm?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)       |
| Ubuntu 2204               | Latest Ubuntu 2204                                                       | `create_ubuntu2204`             |                                                                                                                                                                       |
| Ubuntu 2204 cnspec        | Latest Ubuntu 2204 with latest 2204                                      | `create_ubuntu2204_cnspec`      |                                                                                                                                                                       |
| Ubuntu 2204 CIS           | CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1                           | `create_ubuntu2204_cis`         | [CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-7afxz7ijttzk4?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)         |
| Ubuntu 2204 CIS cnspec    | CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1 with latest cnspec        | `create_ubuntu2204_cis_cnspec`  | [CIS Ubuntu Linux 22.04 LTS Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-7afxz7ijttzk4?sr=0-1&ref_=beagle&applicationId=AWSMPContessa)         |
| Rocky 9                   | Latest Rocky 9 image                                                     | `create_rocky9`                 |                                                                                                                                                                       |
| Rocky 9 cnspec            | Latest Rocky 9 image with latest cnspec                                  | `create_rocky9_cnspec`          |                                                                                                                                                                       |
| Rocky 9 CIS               | CIS Rocky Linux 9 Benchmark - Level 1                                    | `create_rocky9_cis`             | [CIS Rocky Linux 9 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-4dof2bylegr46?sr=0-39&ref_=beagle&applicationId=AWSMPContessa)                 |
| Rocky 9 CIS cnspec        | CIS Rocky Linux 9 Benchmark - Level 1 with latest cnspec                 | `create_rocky9_cis_cnspec`      | [CIS Rocky Linux 9 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-4dof2bylegr46?sr=0-39&ref_=beagle&applicationId=AWSMPContessa)                 |
| Windows 2016              | Latest Windows 2016 Server                                               | `create_windows2016`            | N/A                                                                                                                                                                   |
| Windows 2016 cnspec       | Latest Windows 2016 Server with latest cnspec                            | `create_windows2016_cnspec`     | N/A                                                                                                                                                                   |
| Windows 2016 CIS          | CIS Microsoft Windows Server 2016 Benchmark - Level 2                    | `create_windows2016_cis`        | [CIS Microsoft Windows Server 2016 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-mytoha3qyuk7y?sr=0-9&ref_=beagle&applicationId=AWSMPContessa)  |
| Windows 2016 CIS cnspec   | CIS Microsoft Windows Server 2016 Benchmark - Level 2 with latest cnspec | `create_windows2016_cis_cnspec` | [CIS Microsoft Windows Server 2016 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-mytoha3qyuk7y?sr=0-9&ref_=beagle&applicationId=AWSMPContessa)  |
| Windows 2019              | Latest Windows 2019 Server                                               | `create_windows2019`            | N/A                                                                                                                                                                   |
| Windows 2019 cnspec       | Latest Windows 2019 Server with latest cnspec                            | `create_windows2019_cnspec`     | N/A                                                                                                                                                                   |
| Windows 2019 CIS          | CIS Microsoft Windows Server 2019 Benchmark - Level 2                    | `create_windows2019_cis`        | [CIS Microsoft Windows Server 2019 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-zgh6fzj3hbf7o?sr=0-11&ref_=beagle&applicationId=AWSMPContessa) |
| Windows 2019 CIS cnspec   | CIS Microsoft Windows Server 2019 Benchmark - Level 2 with latest cnspec | `create_windows2019_cis_cnspec` | [CIS Microsoft Windows Server 2019 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-zgh6fzj3hbf7o?sr=0-11&ref_=beagle&applicationId=AWSMPContessa) |
| Windows 2022              | Latest Windows 2022 Server                                               | `create_windows2022`            | N/A                                                                                                                                                                   |
| Windows 2022 cnspec       | Latest Windows 2022 Server with latest cnspec                            | `create_windows2022_cnspec`     | N/A                                                                                                                                                                   |
| Windows 2022 CIS          | CIS Microsoft Windows Server 2022 Benchmark - Level 2                    | `create_windows2022_cis`        | [CIS Microsoft Windows Server 2022 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-lhbxwzmvsawbw?sr=0-19&ref_=beagle&applicationId=AWSMPContessa) |
| Windows 2022 CIS cnspec   | CIS Microsoft Windows Server 2022 Benchmark - Level 2 with latest cnspec | `create_windows2022_cis_cnspec` | [CIS Microsoft Windows Server 2022 Benchmark - Level 2](https://aws.amazon.com/marketplace/pp/prodview-lhbxwzmvsawbw?sr=0-19&ref_=beagle&applicationId=AWSMPContessa) |

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