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
https://github.com/Lunalectric/container-escape
```

2. cd into the dod-amsterdam-hacklab folder

```bash
cd container-escape/minikube
```

3. Initialize the project (download modules)

```bash
terraform init
```

4. Check that everything is ready

```bash
terraform plan
```

5. Apply the configuration

```bash
terraform apply -auto-approve
```

6. Create Hack-Write-up as Markdown

```bash
terraform output | sed "/^EOT/c\ " | sed "/hack_write_up = <<EOT/c\ " | sed 's/\$\\{CSRF\\}/\${CSRF}/g' > Hack-writeup.md
```

Once the provisioning completes you will see something like this:

```bash
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

hack_write_up = <<EOT
# Minikube hack

- login to your Ubuntu machine

......
```

## Destroy a single environment

```bash
terraform apply -destroy -auto-approve
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