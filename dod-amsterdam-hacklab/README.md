# DOD Amsterdam Hacklab

This folder contains Terraform automation code to provision the following:

- **AWS VPC**
- **Kali Linux AWS EC2 Instance** - This instance is provisioned for the demonstration of the container-escape and windows hack.
- **Ubuntu 20.04 AWS EC2 Instance** - This instance is provisioned for the minikube and to demonstrate the container escape
- **Windows 2016** - This instance is provisioned for the demonstration of the Windows Hack and Printnightmare vulnerability. (ami-0808d6a0d91e57fd3 in eu-central-1)

### Prerequsites

- [AWS Account](https://aws.amazon.com/free/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) - `~> aws-cli/2.4.28`
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) - `~> v1.0.5`
- [AWS EC2 Key Pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html) - You should already have an AWS key pair created and uploaded to the region where you want to provision.

## Configuration

Before provisioning set the following environment variables:

- `TF_VAR_region` - AWS region where you want to provision the cluster.
- `TF_VAR_demo_name` - This is a prefix that will be applied to all provisioned resources (i.e. `your_name`).
- `TF_VAR_ssh_key` - AWS EC2 key pair for Kali linux access.
- `TF_VAR_ssh_key_path` - Path to to local ssh key for connecting to Kali Linux instance.
- `TF_VAR_publicIP` - IP address of your home network to be applied to the security group for the Kali Linux, Ubuntu and Windows instance. example: `1.1.1.1/32`

### Example configuration 

Open a terminal and run the following commands:

```bash
export TF_VAR_region=eu-central-1

export TF_VAR_demo_name=dod-amsterdam

export TF_VAR_ssh_key=patrick-key

export TF_VAR_publicIP="1.1.1.1/32"
```

## Provision a single environment

1. Clone the project
```bash title="Clone the project"
git clone git@github.com:mondoohq/demos.git
```

2. cd into the dod-amsterdam-hacklab folder
```
cd demos/dod-amsterdam-hacklab
```

3. Initialize the project (download modules)

```
terraform init
```

4. Check that everything is ready

```
terraform plan
```

5. Apply the configuration

```
terraform apply -auto-approve
```

Once the provisioning completes you will see something like this:

```bash
Apply complete! Resources: 32 added, 0 changed, 0 destroyed.

Outputs:

kali_linux_public_ip = <<EOT

################################################################################
# KALI LINUX SSH:
################################################################################

Username and password:
kali:4ecomY1T

ssh command:
ssh kali@18.195.64.139

private ip:
10.0.4.41


EOT
ubuntu_k8s_public_ip = <<EOT

################################################################################
# Ubuntu K8s LINUX SSH:
################################################################################

Username and password:
ubuntu:4ecomY1T

ssh command:
ssh ubuntu@3.68.167.38

private ip:
10.0.4.165


EOT
windows_public_ip = <<EOT

################################################################################
# Windows RDP Access:
################################################################################
  
xfreerdp /u:Administrator /v:3.120.248.145:3389 /h:2048 /w:2048 /p:'Password1!'

private ip:
10.0.4.231


EOT
```

## Destroy a single environment

```bash
terraform apply -destroy -auto-approve
```

## Provision multiple environments

1. create a `set-exports.sh`

```bash
#!/bin/bash

export AWS_PROFILE=mondoo-demo-dod

export TF_VAR_region=eu-central-1

export TF_VAR_demo_name=dod-amsterdam

export TF_VAR_ssh_key=patrick-key

export TF_VAR_publicIP="1.1.1.1/32"
```

2. execute `multi_deploy.sh` script

- this example creates 2 deployments

```bash
./multi_deploy.sh -c 2
```

- it create two folders `deployments/1` and `deployments/2` with the terraform stuff
- the output from each terraform run is saved under `deployments/1/terraform-run.log` and `deployments/2/terraform-run.log`
- this outputs contain the ip's and the passwords to connect to the ec2 instances

## Destroy multiple environments

1. execute `multi_destroy.sh` script

- this example destroy 2 deployments, which are created via the `./multi_deploy.sh -c 2`

```bash
./multi_destroy.sh -c 2
```

## License and Author

* Author:: Mondoo Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Disclaimer

This or previous program is for Educational purpose ONLY. Do not use it without permission. The usual disclaimer applies, especially the fact that we (Mondoo Inc) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (dataloss, system crash, system compromise, etc.) caused by the use of these programs is not Mondoo Inc's responsibility.