# Windows VMs in Azure with SentinelOne

Provisions four Windows VMs in a single Azure resource group and registers
each one with an existing SentinelOne console via the agent's site token.

## Platforms

| VM                      | Variable                       |
|-------------------------|--------------------------------|
| Windows 10 Enterprise   | `create_windows10`             |
| Windows 11 Enterprise   | `create_windows11`             |
| Windows Server 2022     | `create_windows_server_2022`   |
| Windows Server 2025     | `create_windows_server_2025`   |

All four default to `true`. Set one to `false` to skip a VM. All VMs share one
resource group, vnet, subnet and NSG.

## Prerequisites

- Azure subscription + `az` CLI logged in (`az login --use-device-code`)
- Terraform >= 1.5
- An existing SentinelOne console
- A SentinelOne **scope token** (Sentinels → Agent management → Packages →
  copy the "Scope Token" at the top of the page). Older docs call this a
  "site token" — same value, the MSI install parameter is still
  `SITE_TOKEN`.
- The SentinelOne Windows agent `.msi`, downloaded locally. From the same
  Packages page, download the Windows MSI manually through your logged-in
  browser. Terraform will upload it to an Azure Storage Account it creates
  and hand the VMs a read-only SAS URL — no manual blob hosting needed.

## Configure

Create `terraform.tfvars`:

```hcl
tenant_id       = "00000000-0000-0000-0000-000000000000"
subscription_id = "00000000-0000-0000-0000-000000000000"

publicIP = "1.2.3.4/32" # your egress IP, allowed for RDP (3389) and SSH (22)

sentinelone_site_token     = "REPLACE_WITH_S1_SCOPE_TOKEN"              # from the S1 console
sentinelone_installer_path = "./SentinelOneInstaller_windows_64bit.exe" # .msi or .exe both work

# Optional overrides
# location = "westeurope"
# vm_size  = "Standard_D2s_v3"
# windows_admin_password = "ChangeMe-very-long-pw!"  # default: generated random
# create_windows10           = true
# create_windows11           = true
# create_windows_server_2022 = true
# create_windows_server_2025 = true
```

The `windows_admin_password` defaults to a randomly-generated 24-char
password — grab it with `terraform output -raw rdp_credentials` after
apply.

## Apply

```bash
az login --use-device-code
terraform init --upgrade
terraform plan -out plan.out
terraform apply plan.out
```

## After apply

```bash
terraform output vm_summary
terraform output -raw rdp_credentials   # shows username + password
```

The Custom Script Extension installs the agent on first boot. Logs land on
the VM at:

- `C:\sentinelone-install.log` (PowerShell transcript)
- `C:\sentinelone-msi.log` (MSI verbose log)

The new hosts should appear in the SentinelOne console within a few minutes
of `terraform apply` finishing.

## SSH access

The install script enables Windows OpenSSH Server on every VM and the NSG
opens port 22 to `var.publicIP`. Connect with the same local admin
credentials used for RDP:

```bash
ssh adminuser@<public-ip-or-fqdn>
```

Password auth only (no key auth is configured). Get the password with
`terraform output -raw rdp_credentials`.

## Find image SKUs

```bash
az vm image list --publisher MicrosoftWindowsDesktop --offer windows-11    --all -o table
az vm image list --publisher MicrosoftWindowsServer  --offer WindowsServer --all -o table
```

Adjust the SKUs in `main.tf` (`local.vm_definitions`) if you want a different
edition (e.g. non-Azure-edition server SKUs, or a different Win10/11 build).
