# Azure Intune Prototype

Terraform infrastructure for deploying Windows 11 VMs with intentionally vulnerable software baselines, Azure AD join, Intune MDM enrollment, and Mondoo security scanning.

## Architecture

The infrastructure is split into two layers with independent lifecycles:

```
azure-intune/
├── Makefile                # Root-level orchestration (full lifecycle)
├── foundation/             # Persistent layer (deploy once)
│   ├── main.tf             # Resource group, storage account, Azure AD app
│   ├── outputs.tf
│   ├── providers.tf
│   └── variables.tf
├── testbed/                # Ephemeral layer (tear down / rebuild freely)
│   ├── main.tf             # VNet, Windows VMs, RBAC, Mondoo
│   ├── mondoo.tf           # Optional Mondoo space + registration token
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── environments/
│   │   └── dev/
│   │       └── terraform.tfvars.example
│   └── installers/         # Binary installers (tracked via Git LFS)
│       ├── 7zip/
│       ├── adobe/
│       ├── chrome/
│       ├── java/
│       ├── zoom/
│       └── scripts/        # PowerShell scripts
│           ├── vm-setup.ps1
│           └── remediation/
│               └── CVE-2024-20726/
└── modules/
    ├── network/            # VNet, subnet, NSG
    └── windows-vm/         # Windows VM + AAD join + setup script
        └── scripts/
            └── vm-setup.ps1
```

### Foundation (`foundation/`)

Persistent resources that survive testbed teardowns:

- **Resource Group**: `rg-intune-prototype-foundation-<suffix>`
- **Storage Account**: Blob storage for vulnerable software installers (`vulnerable-apps` container)
- **Azure AD App Registration**: Service principal with Microsoft Graph permissions for Intune API access (device management, configuration, apps, scripts)

### Testbed (`testbed/`)

Ephemeral resources that can be destroyed and rebuilt without affecting the foundation:

- **Resource Group**: `rg-hackathon-intune-<suffix>`
- **Virtual Network**: VNet + subnet + NSG (with optional RDP access)
- **Windows 11 VMs**: Two workstations (`hackathon-intune-workstation-1`, `hackathon-intune-workstation-2`) provisioned with a vulnerable software baseline
- **Mondoo Integration**: Optional space + registration token for vulnerability scanning
- **RBAC**: VM Administrator Login role assignments for Azure AD RDP

The testbed reads foundation outputs via `terraform_remote_state`.

### Vulnerable Software Baseline

Each VM is provisioned with these intentionally outdated applications:

| Software | Version | Notable CVEs |
|---|---|---|
| 7-Zip | 23.01 | CVE-2024-11477 (fixed in 24.07) |
| Google Chrome | 120.0.6099.109 | Multiple CVEs |
| Zoom | 5.16.2 | CVE-2024-24691 (fixed in 5.16.5) |
| Adobe Reader DC | 23.006.20380 | Multiple CVEs |
| AdoptOpenJDK JRE 8 | 8u202 | CVE-2019-2699 (fixed in 8u211) |

Chrome auto-updates are disabled via group policy to preserve the vulnerable version.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az login` authenticated)
- [Git LFS](https://git-lfs.github.com/) (binary installers are tracked via LFS)
- [direnv](https://direnv.net) (optional, for environment variable management)
- Mondoo API token (optional, for vulnerability scanning)

### Terraform State

Both layers use local state files (`terraform.tfstate` in each directory). The testbed reads foundation outputs via a local `terraform_remote_state` reference.

## Quick Start

All commands run from the repository root using the Makefile.

### 1. Initialize

```bash
make init
```

### 2. Deploy Foundation (one-time)

```bash
make deploy-foundation
```

### 3. Upload Installers

The vulnerable software installers are included in `testbed/installers/` (tracked via Git LFS). Upload them to blob storage:

```bash
make upload-installers
```

### 4. Deploy Testbed

```bash
make deploy-testbed
```

This auto-generates a VM admin password and prints it to stdout. To provide your own:

```bash
make deploy-testbed VM_ADMIN_PASSWORD="YourSecurePassword123!"
```

### 5. Full Deploy (both layers)

```bash
make deploy
```

## Makefile Targets

```
make help
```

| Target | Description |
|---|---|
| `help` | Show all targets and variables |
| `init` | Run `terraform init` in both layers |
| `plan` | Run `terraform plan` on both layers |
| `plan-foundation` | Plan foundation only |
| `plan-testbed` | Plan testbed only |
| `deploy` | Deploy everything (foundation then testbed) |
| `deploy-foundation` | Deploy foundation layer only |
| `deploy-testbed` | Deploy testbed layer (auto-generates password if not set) |
| `destroy` | Destroy testbed only (preserves foundation/storage) |
| `destroy-all` | Destroy testbed first, then foundation |
| `status` | Show terraform state for both layers |
| `output` | Show terraform outputs from both layers |
| `upload-installers` | Upload installer files to blob storage |

### Variables

| Variable | Default | Description |
|---|---|---|
| `AUTO_APPROVE` | _(unset)_ | Set to `1` for `-auto-approve` |
| `ENABLE_RDP` | `true` | Enable RDP access (public IPs + port 3389) |
| `VM_ADMIN_PASSWORD` | _(auto-generated)_ | VM admin password (printed to stdout if generated) |
| `MONDOO_ORG_ID` | _(empty)_ | Mondoo organization ID |
| `MONDOO_API_TOKEN` | _(empty)_ | Mondoo API token (skips Mondoo if empty) |
| `INSTALLERS_DIR` | `./testbed/installers` | Local path to installer files |

Examples:

```bash
# Deploy with auto-approve and RDP disabled
make deploy AUTO_APPROVE=1 ENABLE_RDP=false

# Deploy with Mondoo integration
make deploy-testbed MONDOO_ORG_ID=myorg MONDOO_API_TOKEN=eyJ...

# Plan only
make plan

# Destroy testbed, keep foundation
make destroy AUTO_APPROVE=1

# Destroy everything
make destroy-all
```

## Tear Down

### Testbed only (preserves foundation storage and Azure AD app)

```bash
make destroy
```

### Full teardown

```bash
make destroy-all
```

## RDP Access

When `ENABLE_RDP=true` (the default), each VM gets a public IP with port 3389 open. Connect using Azure AD credentials:

```bash
# Get public IPs
make output
```

Use an RDP client that supports Azure AD authentication. NLA is disabled on the VMs to allow Azure AD login.
