# =============================================================================
# Root-level Makefile — Full Infrastructure Lifecycle Orchestration
# =============================================================================
# Usage:
#   make help                  Show all available targets
#   make init                  Initialize terraform in both layers
#   make deploy                Deploy everything (init → foundation → testbed)
#   make destroy               Destroy testbed only (preserves foundation)
#   make destroy-all           Destroy testbed then foundation
#
# Variables:
#   AUTO_APPROVE=1             Skip interactive approval prompts
#   ENABLE_RDP=true|false      Enable RDP access to VMs (default: true)
#   VM_ADMIN_PASSWORD=...      Set VM password (auto-generated if omitted)
#   MONDOO_ORG_ID=...          Mondoo organization ID (optional)
#   MONDOO_API_TOKEN=...       Mondoo API token (optional)
#   INSTALLERS_DIR=./path      Path to installer files (default: ./installers)
# =============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Optional: source secrets from prep-dev.sh if it exists
# -----------------------------------------------------------------------------
-include .env.mk
ifneq (,$(wildcard prep-dev.sh))
  $(shell bash -c 'source prep-dev.sh 2>/dev/null && env' > /tmp/.makefile_env)
  $(eval MONDOO_API_TOKEN ?= $(shell grep '^MONDOO_API_TOKEN=' /tmp/.makefile_env | cut -d= -f2-))
  $(eval MONDOO_ORG_ID ?= $(shell grep '^MONDOO_ORG_ID=' /tmp/.makefile_env | cut -d= -f2-))
endif

# -----------------------------------------------------------------------------
# Directories
# -----------------------------------------------------------------------------
FOUNDATION_DIR := foundation
TESTBED_DIR    := testbed

# -----------------------------------------------------------------------------
# User-overridable variables
# -----------------------------------------------------------------------------
ENABLE_RDP     ?= true
INSTALLERS_DIR ?= ./testbed/installers
AUTO_APPROVE   ?=

# Password: use provided value or auto-generate
ifndef VM_ADMIN_PASSWORD
  VM_ADMIN_PASSWORD := $(shell openssl rand -base64 24)
  PASSWORD_GENERATED := 1
endif

# Optional Mondoo variables (pass through from env)
MONDOO_ORG_ID  ?=
MONDOO_API_TOKEN ?=

# -----------------------------------------------------------------------------
# Computed flags
# -----------------------------------------------------------------------------
ifeq ($(AUTO_APPROVE),1)
  TF_AUTO_APPROVE := -auto-approve
else
  TF_AUTO_APPROVE :=
endif

# Build -var flags for testbed
TESTBED_VARS := -var="vm_admin_password=$(VM_ADMIN_PASSWORD)" \
                -var="enable_rdp_access=$(ENABLE_RDP)"

ifneq ($(MONDOO_ORG_ID),)
  TESTBED_VARS += -var="mondoo_org_id=$(MONDOO_ORG_ID)"
endif

ifneq ($(MONDOO_API_TOKEN),)
  TESTBED_VARS += -var="mondoo_api_token=$(MONDOO_API_TOKEN)"
endif

# =============================================================================
# Phony targets
# =============================================================================
.PHONY: help init deploy deploy-foundation deploy-testbed \
        destroy destroy-all \
        plan plan-foundation plan-testbed \
        status output upload-installers \
        _init-foundation _init-testbed \
        _deploy-foundation _deploy-testbed _print-password

# =============================================================================
# help
# =============================================================================

help: ## Show this help message
	@echo ""
	@echo "Azure Intune Infrastructure — Makefile Targets"
	@echo "==============================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  AUTO_APPROVE=1             Skip interactive approval prompts"
	@echo "  ENABLE_RDP=true|false      Enable RDP access (default: true)"
	@echo "  VM_ADMIN_PASSWORD=...      VM admin password (auto-generated if omitted)"
	@echo "  MONDOO_ORG_ID=...          Mondoo organization ID (optional)"
	@echo "  MONDOO_API_TOKEN=...       Mondoo API token (optional)"
	@echo "  INSTALLERS_DIR=./path      Local installers directory (default: ./installers)"
	@echo ""

# =============================================================================
# Internal helpers (not shown in help)
# =============================================================================

_init-foundation:
	@echo "==> Initializing foundation..."
	@terraform -chdir=$(FOUNDATION_DIR) init -input=false

_init-testbed:
	@echo "==> Initializing testbed..."
	@terraform -chdir=$(TESTBED_DIR) init -input=false

_deploy-foundation:
	@echo "==> Deploying foundation..."
	terraform -chdir=$(FOUNDATION_DIR) apply $(TF_AUTO_APPROVE)

_deploy-testbed:
	terraform -chdir=$(TESTBED_DIR) apply $(TF_AUTO_APPROVE) $(TESTBED_VARS)

_print-password:
ifdef PASSWORD_GENERATED
	@echo ""
	@echo "============================================"
	@echo "  Generated VM Admin Password (save this!):"
	@echo "  $(VM_ADMIN_PASSWORD)"
	@echo "============================================"
	@echo ""
endif

# =============================================================================
# init
# =============================================================================

init: _init-foundation _init-testbed ## Run terraform init in both layers

# =============================================================================
# plan
# =============================================================================

plan: plan-foundation plan-testbed ## Run terraform plan on both layers

plan-foundation: ## Plan foundation layer only
	@echo "==> Planning foundation..."
	terraform -chdir=$(FOUNDATION_DIR) plan

plan-testbed: ## Plan testbed layer only
	@echo "==> Planning testbed..."
	terraform -chdir=$(TESTBED_DIR) plan $(TESTBED_VARS)

# =============================================================================
# deploy
# =============================================================================

deploy: ## Deploy everything (init → foundation → testbed)
	@$(MAKE) _init-foundation
	@$(MAKE) _init-testbed
	@$(MAKE) _deploy-foundation
	@$(MAKE) _print-password
	@echo "==> Deploying testbed..."
	@$(MAKE) _deploy-testbed

deploy-foundation: _init-foundation _deploy-foundation ## Deploy foundation layer only

deploy-testbed: _init-testbed _print-password ## Deploy testbed layer (generates password if not set)
	@echo "==> Deploying testbed..."
	@$(MAKE) _deploy-testbed

# =============================================================================
# destroy
# =============================================================================

destroy: ## Destroy testbed only (preserves foundation/storage)
	@echo "==> Destroying testbed..."
	terraform -chdir=$(TESTBED_DIR) destroy $(TF_AUTO_APPROVE) $(TESTBED_VARS)

destroy-all: ## Destroy testbed first, then foundation
	@echo "==> Destroying testbed..."
	terraform -chdir=$(TESTBED_DIR) destroy $(TF_AUTO_APPROVE) $(TESTBED_VARS)
	@echo "==> Destroying foundation..."
	terraform -chdir=$(FOUNDATION_DIR) destroy $(TF_AUTO_APPROVE)

# =============================================================================
# status / output
# =============================================================================

status: ## Show terraform state for both layers
	@echo "==> Foundation state:"
	@terraform -chdir=$(FOUNDATION_DIR) show -no-color 2>/dev/null || echo "  (no state)"
	@echo ""
	@echo "==> Testbed state:"
	@terraform -chdir=$(TESTBED_DIR) show -no-color 2>/dev/null || echo "  (no state)"

output: ## Show terraform outputs from both layers
	@echo "==> Foundation outputs:"
	@terraform -chdir=$(FOUNDATION_DIR) output 2>/dev/null || echo "  (no outputs)"
	@echo ""
	@echo "==> Testbed outputs:"
	@terraform -chdir=$(TESTBED_DIR) output 2>/dev/null || echo "  (no outputs)"

# =============================================================================
# upload-installers
# =============================================================================

upload-installers: ## Upload vulnerable software installers to blob storage
	$(eval STORAGE_ACCOUNT := $(shell terraform -chdir=$(FOUNDATION_DIR) output -raw installer_storage_account_name))
	@echo "==> Uploading installers to storage account: $(STORAGE_ACCOUNT)"
	@echo ""
	@for blob in \
		"scripts/vm-setup.ps1" \
		"scripts/remediation/CVE-2024-20726/detection.ps1" \
		"scripts/remediation/CVE-2024-20726/remediation.ps1" \
		"7zip/7z2301-x64.exe" \
		"chrome/googlechromestandaloneenterprise64-120.0.6099.109.msi" \
		"zoom/ZoomInstallerFull-5-16-2.msi" \
		"adobe/AcroRdrDC2300620380_en_US.exe" \
		"java/OpenJDK8U-jre_x64_windows_hotspot_8u202b08.msi"; \
	do \
		local_file="$(INSTALLERS_DIR)/$$blob"; \
		if [ -f "$$local_file" ]; then \
			echo "  Uploading $$blob ..."; \
			az storage blob upload \
				--account-name $(STORAGE_ACCOUNT) \
				--container-name vulnerable-apps \
				--name "$$blob" \
				--file "$$local_file" \
				--overwrite \
				--auth-mode key 2>/dev/null; \
		else \
			echo "  SKIP $$blob (file not found: $$local_file)"; \
		fi; \
	done
	@echo ""
	@echo "==> Upload complete."
