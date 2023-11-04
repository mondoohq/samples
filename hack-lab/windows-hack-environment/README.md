# Windows Hack Demo

This folder contains Terraform automation code to provision the following:

- **AWS VPC**
- **Kali Linux AWS EC2 Instance** - This instance is provisioned for the demonstration of the Windows hack, it is the attacker vm.
- **Windows 2022 AD** - This instance is provisioned for the demonstration of Windows Active Directory hacks.
- **Windows 2016 Exchange** - This instance is provisioned for the demonstration of the Windows Exchange hacks.
- **Windows 2016 DVWA** - This instance is provisioned for the demonstration of the Windows Hack and Printnightmare vulnerability/ DVWA App hack. (ami-0808d6a0d91e57fd3 in eu-central-1)


### Prerequsites

- [AWS Account](https://aws.amazon.com/free/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) - `~> aws-cli/2.4.28`
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) - `~> v1.0.5`
- [AWS EC2 Key Pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html) - You should already have an AWS key pair created and uploaded to the region where you want to provision.
- [Ansible](https://www.ansible.com/)

#### Ansible

Install the following Ansible collections

```bash
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
ansible-galaxy collection install microsoft.ad
ansible-galaxy collection install chocolatey.chocolatey
```

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
export TF_VAR_region=us-east-1

export TF_VAR_demo_name=Mondoo-hacking

export TF_VAR_ssh_key=key

export TF_VAR_ssh_key_path="~/.ssh/key.pem"

export TF_VAR_publicIP="1.1.1.1/32"

export TF_VAR_admin_password="MondooSPM1!"
```

```bash title="set-exports.sh"
#!/bin/bash

export AWS_REGION=us-east-1
export AWS_PROFILE=default
export TF_VAR_region=us-east-1
export TF_VAR_demo_name=Mondoo-hacking
export TF_VAR_ssh_key=key
export TF_VAR_ssh_key_path="~/.ssh/key.pem"
export TF_VAR_publicIP="1.1.1.1/32"
```

## Provision a single environment

1. Clone the project
```bash title="Clone the project"
git clone git@github.com:Lunalectric/windows-hack-environment.git
```

2. cd into the windows-hack-demo folder

```
cd windows-hack-environment
```

3. Initialize the project (download modules)

```
terraform init
```

4. Check that everything is ready

```
terraform plan -out plan.out
```

5. Apply the configuration

```
terraform apply -auto-approve plan.out
```

Once the provisioning completes you will see something like this:

```bash
Apply complete! Resources: 39 added, 0 changed, 0 destroyed.

Outputs:

hack_write_up = <<EOT

# Windows DC Login

```bash
xfreerdp /u:Administrator /d:mondoo.hacklab /v:52.202.235.62:3389 /h:2048 /w:2048 /p:'MondooSPM1!'
```

private-ip: 10.0.4.10

# Windows Exchange Login

```bash
xfreerdp /u:Administrator /d:mondoo.hacklab /v:54.210.81.194:3389 /h:2048 /w:2048 /p:'MondooSPM1!'
```

private-ip: 10.0.4.11

# Windows DVWA Login

```bash
xfreerdp /u:Administrator /d:mondoo.hacklab /v:54.159.93.101:3389 /h:2048 /w:2048 /p:'MondooSPM1!'
```

private-ip: 10.0.4.168

# Kali Login

```bash
ssh -o StrictHostKeyChecking=no kali@3.94.253.117
```

private-ip: 10.0.4.200


EOT
```

## Destroy a single environment

```bash
terraform apply -destroy -auto-approve
```

## Contributors + Kudos

* Scott Ford [scottford-io](https://github.com/scottford-io)
* Dominik Richter [arlimus](https://github.com/arlimus)
* Christoph Hartmann [chris-rock](https://github.com/chris-rock)
* Patrick Münch [atomic111](https://github.com/atomic111)

Thanks to all of you!!

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