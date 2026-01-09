# Archive Directory

This directory contains legacy files from the original monolithic demo setup that have been replaced by the modular stage-based approach.

## Contents

### legacy-terraform/
Original monolithic Terraform configuration files that managed all resources in a single directory.

**Replaced by**: `terraform/stages/` with persona-based modular stages:
- Stage 1: Platform (control plane)
- Stage 2: Integration (services and routes)
- Stage 3: API Spec Testing (validation and testing)
- Stage 4: API Product (catalog and governance)
- Stage 5: Developer Portal (portal publishing)

**Files archived**:
- `api_catalog.tf` - Now in `stages/4-api-product/catalog.tf`
- `control_plane.tf` - Now in `stages/1-platform/control_plane.tf`
- `developer_portal.tf` - Now in `stages/5-developer-portal/portal.tf`
- `outputs.tf` - Split across stage-specific `outputs.tf` files
- `plugins.tf` - Now in `stages/4-api-product/plugins.tf`
- `provider.tf` - Duplicated in each stage
- `service.tf` - Now in `stages/2-integration/gateway_service.tf`
- `service_catalog.tf` - Merged into catalog.tf
- `variables.tf` - Split across stage-specific `variables.tf` files
- `terraform.tfvars` - Now stage-specific, auto-loaded by demo.sh scripts
- `backend.tf` - Azure backend configuration (no longer used)

### legacy-scripts/
Original shell scripts for automated demo startup that have been replaced by interactive stage-based demo scripts.

**Replaced by**: Individual `demo.sh` scripts in each stage directory with interactive prompts and better error handling.

**Files archived**:
- `start_demo.sh` - Automated startup script for FHIR server and Terraform
  - Now replaced by stage-specific `demo.sh` scripts
  - FHIR server still available via `docker-compose up -d`
  
- `stop_demo.sh` - Automated shutdown script
  - Now use `docker-compose down` directly
  - Terraform cleanup via `terraform destroy` in each stage
  
- `setup_kong_dataplane.sh` - Kong data plane setup script
  - No longer needed as demo uses Konnect control plane only
  - Data plane management is now handled by Konnect platform

## Why These Files Were Archived

1. **Monolithic → Modular**: The original setup managed everything in one Terraform run, making it difficult to demonstrate the persona-based workflow.

2. **Limited Interaction**: Scripts were fully automated, preventing presales demonstrations of incremental progress.

3. **Hard-Coded Values**: Original scripts had hard-coded values instead of interactive prompts.

4. **No Stage Dependencies**: Couldn't show how outputs from one team flow to the next.

5. **Difficult to Debug**: When something failed, the entire demo failed. Now each stage can be debugged independently.

## Migration Path

If you need to reference the old setup:

### Old Workflow
```bash
./start_demo.sh
cd terraform
terraform apply
```

### New Workflow
```bash
# Stage 1: Platform
cd terraform/stages/1-platform && ./demo.sh

# Stage 2: Integration
cd ../2-integration && ./demo.sh

# Stage 3: API Spec Testing
cd ../3-api-spec-testing && ./demo.sh

# Stage 4: API Product
cd ../4-api-product && ./demo.sh

# Stage 5: Developer Portal
cd ../5-developer-portal && ./demo.sh
```

## Recovery

If you need to restore these files:
```bash
# Restore Terraform files
cp .archive/legacy-terraform/*.tf terraform/

# Restore scripts
cp .archive/legacy-scripts/*.sh .
```

## When to Delete

These files can be permanently deleted once:
- [ ] All team members are familiar with the new stage-based approach
- [ ] No customer demos reference the old workflow
- [ ] All documentation has been updated
- [ ] Archived for at least 3 months (consider deleting after: April 2026)

---

**Last Updated**: January 10, 2026  
**Reason**: Transition to persona-based demo stages
