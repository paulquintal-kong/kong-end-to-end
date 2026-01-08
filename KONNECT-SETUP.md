# Kong Konnect Setup Guide

This guide walks you through deploying the FHIR API to Kong Konnect service catalog using Terraform and GitHub Actions.

## Prerequisites

- Kong Konnect account (AU region)
- GitHub repository with secrets configured
- Local environment running (via `start_demo.sh`)

## Architecture

```
Local Environment (start_demo.sh)
  ↓
  ├─ HAPI FHIR Server (Docker)
  ├─ Ngrok Tunnel (Public Access)
  └─ Auto-generates terraform.tfvars
       ↓
GitHub Actions (push to main)
  ↓
  ├─ Terraform Deploy → Kong Konnect (AU)
  │   ├─ Control Plane: "FHIR Patient Records Control Plane"
  │   ├─ Service: "Patient Records API"
  │   └─ Service Catalog with Documentation
  └─ Dev Portal Update (Placeholder)
```

## Step 1: Get Your Kong Konnect Personal Access Token (PAT)

1. Log in to Kong Konnect: https://cloud.konghq.com
2. Navigate to **Personal Access Tokens** in your account settings
3. Click **Generate Token**
4. Name it: `GitHub Actions FHIR Demo`
5. Copy the token (starts with `kpat_`)

**Example:** `kpat_xRqxdyYPVslkxwwjccpA3OqxiWeMS5wOZziQTsKD3wsHgpdfB`

⚠️ **IMPORTANT:** Store this token securely. You won't be able to see it again.

## Step 2: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secret:

| Name | Value | Description |
|------|-------|-------------|
| `KONNECT_PAT` | Your PAT token from Step 1 | Kong Konnect authentication token |

## Step 3: Verify Terraform Configuration

The Terraform configuration is already set up in the `terraform/` directory:

- `provider.tf` - Kong Konnect provider (AU region)
- `variables.tf` - All configuration variables
- `control_plane.tf` - Control plane definition
- `service.tf` - Service and catalog entry
- `outputs.tf` - Output values

### Key Configuration:

```hcl
Region: AU (https://au.api.konghq.com)
Control Plane: "FHIR Patient Records Control Plane"
Service Name: "Patient Records API"
Tags: ["FHIR", "Healthcare", "Patient Data"]
```

## Step 4: Run Local Environment

Start your local FHIR server and ngrok tunnel:

```bash
./start_demo.sh
```

This script will:
1. Start HAPI FHIR server in Docker
2. Create ngrok tunnel for public access
3. **Auto-generate `terraform/terraform.tfvars` with the ngrok URL**
4. Update Insomnia workspace with ngrok URL

**Example output:**
```
✅ Terraform variables updated: terraform/terraform.tfvars
```

The generated `terraform.tfvars` will contain:
```hcl
fhir_server_url = "https://your-tunnel.ngrok-free.dev/fhir"
```

## Step 5: Commit and Push

Commit the auto-generated Terraform variables:

```bash
git add terraform/terraform.tfvars
git commit -m "Update Terraform variables with ngrok URL"
git push origin main
```

## Step 6: Monitor GitHub Actions Deployment

1. Go to **Actions** tab in your GitHub repository
2. Find the **Kong Konnect Deployment** workflow
3. Monitor the progress of two jobs:
   - **Deploy Service Catalog to Konnect** ✅
   - **Update Dev Portal** (disabled until portal URL provided)

### Expected Output:

```
✅ Terraform Init
✅ Terraform Validate
✅ Terraform Plan
✅ Terraform Apply
📊 Deployment Summary
   - Service: Patient Records API
   - Control Plane: FHIR Patient Records Control Plane
   - Region: AU
```

## Step 7: Verify in Kong Konnect

1. Log in to Kong Konnect: https://cloud.konghq.com
2. Navigate to **Service Hub** → **Services**
3. Find **Patient Records API**
4. Verify the service catalog documentation:
   - **Purpose**: FHIR R4 patient data management
   - **Contact**: Healthcare Team (healthcare-team@example.com)
   - **Architecture**: HAPI FHIR v8.6.0, H2 Database, OAuth2/API Key
   - **Dependencies**: HAPI FHIR, H2 Database, Ngrok
   - **Support**: 9-5 AEST, 4hr critical / 24hr standard

## Service Catalog Details

The service is registered with comprehensive documentation:

### Service Configuration
- **Name**: Patient Records API
- **Version**: 1.0.1
- **Tags**: FHIR, Healthcare, Patient Data, catalog, documented
- **Protocol**: HTTPS
- **Host**: Auto-updated from ngrok
- **Path**: /fhir
- **Retries**: 5
- **Timeouts**: 60s (connect/read/write)

### Control Plane Configuration
- **Name**: FHIR Patient Records Control Plane
- **Description**: Dedicated control plane for FHIR patient records API
- **Labels**:
  - `environment`: development
  - `team`: healthcare
  - `api_type`: fhir

## Workflow Details

The GitHub Actions workflow (`.github/workflows/konnect-deploy.yml`) has two jobs:

### Job 1: Deploy Service Catalog to Konnect
- Runs on every push to `main` branch that modifies Terraform files
- Steps:
  1. Checkout code
  2. Setup Terraform
  3. Format check
  4. Initialize Terraform
  5. Validate configuration
  6. Plan deployment
  7. Apply changes (only on `main` branch push)
  8. Generate deployment report

### Job 2: Update Dev Portal (Placeholder)
- Currently disabled (`if: false`)
- Will be enabled once you provide the Dev Portal URL
- Will upload OpenAPI spec to Dev Portal
- Depends on successful service catalog deployment

## Dev Portal Integration (Future)

To enable Dev Portal updates:

1. Create a Dev Portal in Kong Konnect
2. Get the Dev Portal URL
3. Update the workflow:
   - Set `if: false` to `if: true` in `dev-portal-update` job
   - Add steps to upload `.insomnia/fhir-api-openapi.yaml`
4. Add any required secrets (e.g., portal API token)

## Troubleshooting

### Issue: Terraform Apply Fails

**Solution:**
1. Verify `KONNECT_PAT` secret is set correctly
2. Check PAT token has required permissions
3. Ensure `terraform.tfvars` has valid ngrok URL

### Issue: Invalid ngrok URL

**Solution:**
1. Run `./start_demo.sh` to regenerate the URL
2. Commit and push `terraform.tfvars`

### Issue: Service Not Appearing in Catalog

**Solution:**
1. Check Terraform outputs in GitHub Actions logs
2. Verify control plane was created successfully
3. Check Kong Konnect dashboard for errors

### Issue: Authentication Failed

**Solution:**
1. Verify PAT token is correct
2. Check token hasn't expired
3. Ensure AU region is correct for your account

## Manual Terraform Commands (Local Testing)

If you want to test Terraform locally:

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment (requires PAT token)
export TF_VAR_konnect_pat="your_pat_token_here"
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output
```

## Next Steps

1. ✅ Service catalog deployed
2. ⏳ Configure routes (separate workflow - future)
3. ⏳ Configure plugins (separate workflow - future)
4. ⏳ Enable Dev Portal integration (pending portal URL)

## Additional Resources

- [Kong Konnect Documentation](https://docs.konghq.com/konnect/)
- [Terraform Kong Provider](https://registry.terraform.io/providers/Kong/konnect/latest/docs)
- [FHIR R4 Specification](https://hl7.org/fhir/R4/)
- [HAPI FHIR Documentation](https://hapifhir.io/)

## Support

For issues or questions:
- Open a GitHub issue
- Contact: healthcare-team@example.com
- SLA: 4hr critical / 24hr standard (9-5 AEST)
