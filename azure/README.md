## Setup Windows 10/11 VMs in Azure

## Requirements
- A `terraform.tfvars` file containing those two variables:
  ```
  tenant_id = ""
  subscription_id = ""
  ```
- A login to Azure via `azure-cli`
  ```
  az login --use-device-code
  ```


## Setup

### Choosing Windows10/11 (CIS/Vanilla)
Right now you need to still change those values in `main.tf` to change between Windows10 or Windows11:
```
  source_image_reference {
    publisher = "center-for-internet-security-inc"
    offer     = "cis-windows-11-l1"
    sku       = "cis-windows-11-l1"
    version   = "latest"
  }

  plan {
    name = "cis-windows-11-l1"
    product = "cis-windows-11-l1"
    publisher = "center-for-internet-security-inc"
  }
```
The command to look-up the values is something along the lines of (takes some time to complete):
```
az vm image list --offer Windows-11  --output table --all
```


### Terraform commands to deploy Azure VM
```
terraform init --upgrade
```

```
terraform plan -out plan.out
```

```
terraform apply plan.out
```

### Connect to VM using `xfreerdp` from Ubuntu

Run the following command to see the the connection details (including sensitive values)
```
terraform output -raw summary
```