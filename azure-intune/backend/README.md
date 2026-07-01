# Terraform Remote State Backend (Azure)

The Terraform state for this project lives in a **private Azure Blob Storage
container**, not in this repository. State files contain secrets (the Intune app
client secret, the VM admin password, storage keys), so they must never be
committed.

This directory only documents the backend. The storage account itself is
**intentionally not managed by Terraform / not part of the repo** — it is a
bootstrap resource created once with the Azure CLI (a classic chicken-and-egg:
the thing that stores state can't store its own state here).

## Backend resources

| Item | Value |
| --- | --- |
| Subscription | `f1a2873a-6b27-4097-aa7c-3df51f103e96` |
| Resource group | `rg-cz-tfstate` (westeurope) |
| Storage account | `cztfstate464dc4a4` |
| Container | `tfstate` (private — no anonymous access) |
| Blob endpoint | `https://cztfstate464dc4a4.blob.core.windows.net/` |

Hardening applied at creation:

- `allow-blob-public-access = false` (no anonymous blob reads)
- `allow-shared-key-access = false` (**shared/account-key auth disabled** — Azure AD only)
- `min-tls-version = TLS1_2`, HTTPS-only
- Blob **versioning** enabled
- Blob **soft delete** (30 days) and **container soft delete** (30 days)

## Access (who can use it)

Access is **Azure AD only** — the account key is disabled, so handing out keys
is neither possible nor necessary.

| Principal | Role | Scope |
| --- | --- | --- |
| `Mondoo Staff` (AAD group) | `Storage Blob Data Contributor` | the storage account |

Anyone in the **Mondoo Staff** group can read/write state by simply running
`az login` first. Manage access by group membership — no per-user role changes
needed. Note: subscription Owner/Contributor at the management plane does **not**
grant blob data access; the data-plane role above is required.

### State blob keys

Each Terraform config uses its own blob (`key`) in the container:

| Config | Blob key |
| --- | --- |
| `foundation/` | `foundation.terraform.tfstate` |
| `testbed/` | `testbed.terraform.tfstate` |

## How the backend was bootstrapped (one-time)

> Run once by an operator. Not wired into CI or `terraform apply`.

```bash
LOC=westeurope
RG=rg-cz-tfstate
SA=cztfstate464dc4a4          # globally unique; regenerate if recreating

az group create -n "$RG" -l "$LOC"

az storage account create -n "$SA" -g "$RG" -l "$LOC" \
  --sku Standard_LRS --kind StorageV2 \
  --allow-blob-public-access false --min-tls-version TLS1_2 --https-only true \
  --public-network-access Enabled

az storage account blob-service-properties update --account-name "$SA" -g "$RG" \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 30 \
  --enable-container-delete-retention true --container-delete-retention-days 30

KEY=$(az storage account keys list -g "$RG" -n "$SA" --query "[0].value" -o tsv)
az storage container create -n tfstate --account-name "$SA" --account-key "$KEY" --public-access off

# Grant the team group data-plane access, then lock down to Azure AD only.
az role assignment create \
  --assignee-object-id "$(az ad group show --group 'Mondoo Staff' --query id -o tsv)" \
  --assignee-principal-type Group \
  --role "Storage Blob Data Contributor" \
  --scope "$(az storage account show -n "$SA" -g "$RG" --query id -o tsv)"

az storage account update -n "$SA" -g "$RG" --allow-shared-key-access false
```

> The container was created with the account key *before* shared-key access was
> disabled. After the lockdown, all blob operations (including the state upload)
> use `--auth-mode login`.

## Using the backend

1. Copy the example backend config and fill in the access key out-of-band:

   ```bash
   cp backend/backend.hcl.example backend/backend.hcl   # backend.hcl is gitignored
   ```

2. Authenticate via **Azure AD** (the only option — shared key is disabled). Make
   sure you're in the `Mondoo Staff` group, then:

   ```bash
   az login
   ```

3. Add a backend block to the config you're initializing (set the `key` per the
   table above, and `use_azuread_auth = true`). For example, in `testbed/`:

   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "rg-cz-tfstate"
       storage_account_name = "cztfstate464dc4a4"
       container_name       = "tfstate"
       key                  = "testbed.terraform.tfstate"
       use_azuread_auth     = true
     }
   }
   ```

4. Initialize / migrate local state into the backend:

   ```bash
   cd testbed
   terraform init -migrate-state
   ```

   The current local state has already been **uploaded** to the matching blob
   keys, so `terraform init` will find existing remote state. Migrating again is
   idempotent (the content is identical).

## Security notes

- **Shared-key auth is disabled**, so there is no account key to leak or share.
  Access is via Azure AD identity only, scoped through the `Mondoo Staff` group.
- Every access is tied to a real user identity (auditable) and is revoked simply
  by removing the user from the group.
- State blobs contain secrets — keep the container private and the role scoped.
- Versioning + soft delete are on, so an accidental bad apply or delete can be
  recovered for 30 days.
