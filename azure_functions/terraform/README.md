# Azure App Services & Functions - CIS Compliance Testing Framework

This Terraform configuration deploys Azure App Services and Functions with both **vanilla** (non-compliant) and **hardened** (CIS-compliant) configurations for security testing and validation.

## 📋 Overview

### What This Framework Deploys

This framework provisions **24 test assets** (default) across **3 asset categories** and **3 language stacks**:

#### Asset Categories (4 types)
1. **App Service Apps** (Linux Web Apps)
2. **Function Apps** (Linux)
3. **Web App Deployment Slots** (requires S1+)
4. **Function App Deployment Slots** (requires S1+)

#### Configuration Types (2 variants)
- **Vanilla:** Non-compliant configuration (deprecated versions, insecure settings)
- **Hardened:** CIS Benchmark Level 1 + 2 compliant

#### Language Stacks (3 runtimes)
- **Python:** 3.7 (vanilla) vs 3.13 (hardened)
  - Supported by: Web Apps and Functions
  - Configuration: Simple (1 parameter: `python_version`)

- **PHP:** 7.4 (vanilla) vs 8.3 (hardened)
  - Supported by: **Web Apps only** (Functions don't support PHP)
  - Configuration: Simple (1 parameter: `php_version`)

- **Java:** 11 (vanilla) vs 17 (hardened)
  - Supported by: Web Apps and Functions
  - **Web Apps Configuration:** Complex (3 parameters: `java_version`, `java_server`, `java_server_version`)
  - **Function Apps Configuration:** Simple (1 parameter: `java_version` only)
  - Default: Java SE (Standard Edition) for Web Apps

> **Important Notes:**
> - PHP is only deployed for Web Apps and Web App Slots (Azure Functions don't support PHP)
> - Java configuration differs by resource type:
>   - **Web Apps**: Require 3 parameters (version + server + server_version)
>   - **Function Apps**: Require only 1 parameter (version only)

#### Total Assets (Default with S1 SKU)
**20 test assets** (PHP excluded from Functions)
- 6 Web Apps (2 configs × 3 languages: Python, PHP, Java)
- 4 Function Apps (2 configs × 2 languages: Python, Java - no PHP)
- 6 Web App Slots (2 configs × 3 languages: Python, PHP, Java)
- 4 Function App Slots (2 configs × 2 languages: Python, Java - no PHP)

#### With B1 SKU (No Slots)
**10 test assets** (PHP excluded from Functions)
- 6 Web Apps (2 configs × 3 languages: Python, PHP, Java)
- 4 Function Apps (2 configs × 2 languages: Python, Java - no PHP)

### Purpose

- **Validate CIS Microsoft Azure Compute Services Benchmark v2.0.0**
- **Compare vanilla vs hardened configurations** using Mondoo security scanning
- **Test ~90% of CIS controls** (infrastructure-focused controls)

### Cost Estimate

**Default Configuration (S1 with deployment slots):**
- **App Service Plan (S1):** ~$70/month
- **Storage Account:** ~$5/month
- **Total:** ~$75-80/month (ephemeral deployment for testing)

**Budget-Optimized Configuration (B1 without deployment slots):**
- **App Service Plan (B1):** ~$13/month
- **Storage Account:** ~$5/month
- **Total:** ~$18-23/month (limited testing, no deployment slots)

> 💡 **Note:** Default is S1 to enable full testing with deployment slots. You can switch to B1 in `variables.tf` if budget-constrained.

---

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** (2.50.0+)
   ```bash
   az --version
   az login
   ```

2. **Terraform** (1.5.0+)
   ```bash
   terraform --version
   ```

3. **Mondoo CLI** (optional, for scanning)
   ```bash
   cnspec version
   cnspec login
   ```

4. **Azure Subscription**
   - Contributor role on subscription or resource group
   - Subscription ID ready

### Deployment Steps

#### 1. Configure Variables

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your subscription ID:
```hcl
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
owner_email     = "your-email@example.com"

# SKU Configuration
app_service_plan_sku = "S1"          # S1 = deployment slots enabled (~$75/month)
# app_service_plan_sku = "B1"        # B1 = no slots, cost-optimized (~$18/month)
enable_deployment_slots = true       # Set to false if using B1

# Asset Filtering (default: deploy all combinations)
config_types_to_deploy = ["vanilla", "hardened"]  # or ["vanilla"] or ["hardened"]
stacks_to_deploy = ["python", "php", "java"]      # or any subset like ["python"]
```

**Configuration Options:**

| Setting | Default | Options | Result |
|---------|---------|---------|--------|
| **SKU** | `S1` | `S1`, `B1` | S1 = 20 assets, B1 = 10 assets |
| **Configs** | `["vanilla", "hardened"]` | Any subset | Filter by config type |
| **Stacks** | `["python", "php", "java"]` | Any subset | Filter by language (PHP web only) |

**Examples:**
- **Full Testing (Default):** All 20 assets with S1 (PHP excluded from Functions)
- **Python Only:** Set `stacks_to_deploy = ["python"]` → 8 assets (4 with B1)
- **Hardened Only:** Set `config_types_to_deploy = ["hardened"]` → 10 assets (5 with B1)
- **Budget Mode:** Use B1 SKU → 10 assets (no deployment slots)

#### 2. Initialize Terraform

```bash
terraform init
```

#### 3. Review Planned Changes

```bash
terraform plan
```

Expected resources: 23 total (default with S1, all stacks)
- 1 Resource Group
- 1 App Service Plan (S1)
- 1 Storage Account
- 6 Web Apps (2 configs × 3 languages: Python, PHP, Java)
- 4 Function Apps (2 configs × 2 languages: Python, Java)
- 6 Web App Slots (2 configs × 3 languages: Python, PHP, Java)
- 4 Function App Slots (2 configs × 2 languages: Python, Java)

**With B1 SKU:** 13 total resources (10 test assets, no slots)
**Python Only (S1):** 11 total resources (8 test assets: 4 web + 4 function, with slots)
**Python Only (B1):** 7 total resources (4 test assets: 2 web + 2 function, no slots)

#### 4. Deploy Infrastructure

```bash
terraform apply
```

Review and type `yes` to confirm.

Deployment takes approximately **5-10 minutes**.

#### 5. Verify Deployment

```bash
terraform output deployment_summary
```

---

## 🔍 Mondoo Scanning

### Get Scan Commands

After deployment, retrieve copy-paste Mondoo scan commands:

```bash
terraform output mondoo_scan_commands
```

### Example Scan Commands

```bash
# Scan vanilla Python web app (expect failures)
cnspec scan azure --subscription YOUR_SUB_ID --discover app-services \
  --asset-name mondoo-app-webapp-vanilla-python-XXXX

# Scan hardened Python web app (expect passes)
cnspec scan azure --subscription YOUR_SUB_ID --discover app-services \
  --asset-name mondoo-app-webapp-hardened-python-XXXX

# Scan vanilla PHP web app (PHP only supported in Web Apps, not Functions)
cnspec scan azure --subscription YOUR_SUB_ID --discover app-services \
  --asset-name mondoo-app-webapp-vanilla-php-XXXX

# Scan hardened Java function app
cnspec scan azure --subscription YOUR_SUB_ID --discover functions \
  --asset-name mondoo-func-hardened-java-XXXX

# Scan all assets at once
terraform output mondoo_scan_commands | jq -r '.[]' | xargs -I {} bash -c "{}"
```

### Expected Results

| Asset Type | Configuration | Expected Pass Rate | Expected Failures |
|------------|---------------|-------------------|-------------------|
| Web App | Vanilla | ~10-20% | 15-20 controls |
| Web App | Hardened | ~85-95% | 0-2 controls* |
| Function App | Vanilla | ~10-20% | 15-20 controls |
| Function App | Hardened | ~85-95% | 0-2 controls* |

*Auth controls deferred to Phase 2

---

## 📊 CIS Control Coverage

### Tested Controls (Phase 1)

This deployment tests **~90% of CIS controls**, including:

#### Infrastructure Controls ✅
- HTTPS enforcement
- TLS version (minimum 1.2)
- Public network access restrictions
- FTP/FTPS configuration
- HTTP/2 enablement

#### Security Controls ✅
- Remote debugging disabled
- Client certificate requirements
- Basic authentication settings
- Managed identity configuration

#### Runtime Controls ✅
- Python version validation (3.7 vs 3.13)
- PHP version validation (7.4 vs 8.3)
- Java version validation (11 vs 17)

#### Network Controls ✅
- CORS configuration
- VNet route settings (no VNet in Phase 1)

### Deferred Controls (Phase 2)

The following **~10% of controls** are deferred:

- **App Service Authentication** (CIS 2.x.12) - Requires Azure AD setup
- **VNet Integration** (CIS 2.x.18) - Requires Premium SKUs

---

## 🏗️ Architecture

### Resource Hierarchy (Default: All Languages)

```
Resource Group: mondoo-rg-test-eastus
│
├── App Service Plan: mondoo-plan-webapp-XXXX (S1 - Standard)
│   │
│   ├── Web Apps (6 total)
│   │   ├── mondoo-app-webapp-vanilla-python-XXXX
│   │   │   └── Deployment Slot: staging
│   │   ├── mondoo-app-webapp-vanilla-php-XXXX
│   │   │   └── Deployment Slot: staging
│   │   ├── mondoo-app-webapp-vanilla-java-XXXX
│   │   │   └── Deployment Slot: staging
│   │   ├── mondoo-app-webapp-hardened-python-XXXX
│   │   │   └── Deployment Slot: staging
│   │   ├── mondoo-app-webapp-hardened-php-XXXX
│   │   │   └── Deployment Slot: staging
│   │   └── mondoo-app-webapp-hardened-java-XXXX
│   │       └── Deployment Slot: staging
│   │
│   └── Function Apps (4 total - PHP not supported)
│       ├── mondoo-func-vanilla-python-XXXX
│       │   └── Deployment Slot: staging
│       ├── mondoo-func-vanilla-java-XXXX
│       │   └── Deployment Slot: staging
│       ├── mondoo-func-hardened-python-XXXX
│       │   └── Deployment Slot: staging
│       └── mondoo-func-hardened-java-XXXX
│           └── Deployment Slot: staging
│
└── Storage Account: mondoosatestXXXX
    └── (Required for Function Apps)

Total: 20 test assets (with S1 SKU, PHP excluded from Functions)
```

### Network Architecture (Phase 1)

- **No VNet integration** (cost optimization)
- **Public access** controlled via `public_network_access_enabled`
- Hardened assets have public access disabled but remain accessible via HTTPS

---

## 🔧 Configuration Details

### Vanilla (Non-Compliant) Configuration

| Setting | Value | CIS Violation |
|---------|-------|---------------|
| HTTPS Only | `false` | 2.x.7 |
| TLS Version | `1.0` | 2.x.8 |
| **Python Version** | `3.7` (deprecated) | 2.x.2 |
| **PHP Version** | `7.4` (deprecated) | 2.x.3 |
| **Java Version** | `11` (deprecated) | 2.x.1 |
| Remote Debugging | `enabled` | 2.x.9/10 |
| FTP State | `AllAllowed` | 2.x.5 |
| CORS | `*` | 2.x.17/21 |
| Basic Auth | `enabled` | 2.x.4 |
| Client Certs | `disabled` | 2.x.11 |
| Managed Identity | `none` | 2.x.13 |
| Public Access | `enabled` | 2.x.14 |

### Hardened (CIS-Compliant) Configuration

| Setting | Value | CIS Control |
|---------|-------|-------------|
| HTTPS Only | `true` | 2.x.7 ✓ |
| TLS Version | `1.2` | 2.x.8 ✓ |
| **Python Version** | `3.13` (current) | 2.x.2 ✓ |
| **PHP Version** | `8.3` (current) | 2.x.3 ✓ |
| **Java Version** | `17` (current) | 2.x.1 ✓ |
| Remote Debugging | `disabled` | 2.x.9/10 ✓ |
| FTP State | `Disabled` | 2.x.5 ✓ |
| CORS | `["https://example.com"]` | 2.x.17/21 ✓ |
| Basic Auth | `disabled` | 2.x.4 ✓ |
| Client Certs | `Required` | 2.x.11 ✓ |
| Managed Identity | `SystemAssigned` | 2.x.13 ✓ |
| Public Access | `disabled` | 2.x.14 ✓ |

---

## 🧹 Cleanup

### Destroy All Resources

```bash
terraform destroy
```

Type `yes` to confirm.

This will delete all deployed resources and stop incurring costs.

### Verify Cleanup

```bash
az group list --query "[?name=='mondoo-rg-test-eastus']"
```

Should return empty `[]` if cleanup was successful.

---

## 📁 File Structure

```
terraform/
├── providers.tf              # Azure provider configuration
├── variables.tf              # Input variables with defaults
├── locals.tf                 # Naming conventions and tagging
├── main.tf                   # All resource definitions
├── outputs.tf                # Resource IDs and scan commands
├── terraform.tfvars.example  # Example configuration
└── README.md                 # This file
```

---

## 🔐 Security Considerations

### State Management

- **Phase 1:** Local Terraform state (`terraform.tfstate`)
- **Best Practice:** Do not commit `terraform.tfstate` to version control
- **Future:** Migrate to remote state (Azure Storage) for production use

### Secrets Management

- Storage account access keys stored in Terraform state
- Hardened Function App uses managed identity for storage access
- No hardcoded secrets in configuration files

### Access Control

- Resources tagged with `AutoDelete: true` for easy cleanup
- Hardened assets have public network access disabled
- Client certificates required for hardened assets

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: "Cannot complete the operation because the site will exceed the number of slots allowed for the 'Basic' SKU"
**Cause:** You're using B1 (Basic) SKU which does NOT support deployment slots.
**Solution:** Either:
1. Upgrade to S1 SKU in `terraform.tfvars`:
   ```hcl
   app_service_plan_sku = "S1"
   enable_deployment_slots = true
   ```
2. OR disable deployment slots for B1:
   ```hcl
   app_service_plan_sku = "B1"
   enable_deployment_slots = false
   ```

#### Issue: "Subscription not found"
**Solution:** Verify subscription ID and ensure you're logged in:
```bash
az account show
az account set --subscription YOUR_SUB_ID
```

#### Issue: "Storage account name already exists"
**Solution:** Storage account names must be globally unique. The random suffix should prevent this, but you can manually change the suffix in `locals.tf`.

#### Issue: "App Service Plan SKU not available"
**Solution:** B1 SKU might not be available in all regions. Change `location` variable or upgrade to S1 SKU.

#### Issue: "Python 3.7 not available"
**Solution:** Deprecated versions may be removed by Azure. Update `vanilla_python_version` to an available deprecated version or use "3.9".

#### Issue: "Function App deployment fails"
**Solution:** Ensure storage account is created first. Function Apps require storage accounts for backend storage.

#### Issue: "Unsupported argument: java_server" or "Unsupported argument: java_server_version"
**Cause:** Azure Function Apps do NOT support `java_server` and `java_server_version` parameters (only Web Apps do).
**Solution:** This has been fixed in the configuration. Function Apps now only use `java_version` parameter for Java applications.
**Note:**
- **Web Apps**: Require 3 Java parameters (java_version, java_server, java_server_version)
- **Function Apps**: Require only 1 Java parameter (java_version)

#### Issue: "Unsupported argument: php_version" for Function Apps
**Cause:** Azure Function Apps do NOT support PHP runtime (only Web Apps do).
**Solution:** This has been fixed in the configuration. PHP is automatically excluded from Function App deployments.
**Note:** If you manually set `stacks_to_deploy = ["php"]`, no Function Apps will be created (only Web Apps).

### Validation Commands

```bash
# Check resource group
az group show --name mondoo-rg-test-eastus

# List web apps
az webapp list --resource-group mondoo-rg-test-eastus --output table

# List function apps
az functionapp list --resource-group mondoo-rg-test-eastus --output table

# Check web app configuration
az webapp config show --name YOUR_WEBAPP_NAME --resource-group mondoo-rg-test-eastus
```

---

## 📚 References

### CIS Benchmark
- **Policy File:** `../cis-microsoft-azure-compute-service.mql.yaml`
- **Version:** 2.0.0
- **Sections Covered:**
  - 2.1.x: App Service Apps
  - 2.2.x: App Service Deployment Slots
  - 2.3.x: Function Apps
  - 2.4.x: Function App Deployment Slots

### Azure Documentation
- [App Service Overview](https://docs.microsoft.com/azure/app-service/)
- [Azure Functions Overview](https://docs.microsoft.com/azure/azure-functions/)
- [App Service Security](https://docs.microsoft.com/azure/app-service/overview-security)
- [Managed Identities](https://docs.microsoft.com/azure/app-service/overview-managed-identity)

### Terraform Resources
- [azurerm_linux_web_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app)
- [azurerm_linux_function_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app)
- [azurerm_service_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan)

---

## 🚦 Next Steps

### Phase 2: Enhanced Security (Future)
- Add Azure AD authentication (`auth_settings_v2`)
- Implement VNet integration (requires Premium SKUs)
- Key Vault integration for secrets

### Phase 3: Automation (Future)
- Automated Mondoo scanning
- CI/CD pipeline integration
- Result comparison and reporting
- Remote state configuration

---

## 📝 Notes

- **Ephemeral Infrastructure:** Designed for testing, not production
- **Cost Optimization:** Uses B1 SKU instead of Premium for cost savings
- **Manual Scanning:** Mondoo scanning is manual in Phase 1
- **Local State:** Terraform state is local, not remote

---

## 📧 Support

For issues or questions:
1. Review `TECHNICAL_REQUIREMENTS.md` for detailed specifications
2. Check troubleshooting section above
3. Review Terraform plan output for errors
4. Consult Azure documentation for service-specific issues

---

**Version:** 1.0.1
**Last Updated:** October 30, 2025
**Status:** Phase 1 Complete - Ready for Testing
**Recent Updates:** Fixed Java configuration for Function Apps (java_version only, no server params)

