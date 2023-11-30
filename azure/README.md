# Setup Windows VMs in Azure

## Prereqs

- Azure Account
- Terraform

## Supported Platforms

| Platform              | Description                   | Variable           |
|-----------------------|-------------------------------|--------------------|
| Windows 10 Enterprise | Latest Azure Windows 10 image | `create_windows10` |
| Windows 11 Enterprise | Latest Azure Windows 11 image | `create_windows11` |


## Provision

- A `terraform.tfvars` file containing those two variables:

```coffee
tenant_id = "xxx"
subscription_id = "xxxx"

publicIP="0.0.0.0/0"
create_windows10 = false
create_windows11 = true
```

- A login to Azure via `azure-cli`

```bash
az login --use-device-code
```

```bash
terraform init --upgrade
```

```bash
terraform plan -out plan.out
```

```bash
terraform apply -auto-approve plan.out
```

### Connect to VM using `xfreerdp` from Ubuntu

Run the following command to see the the connection details (including sensitive values)

```bash
terraform output -raw summary
```

## Find Azure Image

The command to look-up the values is something along the lines of (takes some time to complete):

```bash
az vm image list --offer Windows-11  --output table --all
```

### Issues with provisioning using the `locals` variable.

As of now it wasn't possible to provision the images further by simply adding a `locals` variable block, like that:

```
locals {
  windows_user_data_cnspec = <<-EOT
    <powershell>
    $hello = "Hello World"
    $hello | Out-File C:\debug.txt
    </powershell>
  EOT
}
```

and using the
```
custom_data = base64encode(local.windows_user_data_cnspec)
```

in the

```module"windows11"```

the same we would on AWS.