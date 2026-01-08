# Kong Konnect Quick Start

## Setup (One-Time)

1. **Get PAT Token**
   ```
   Login: https://cloud.konghq.com
   Go to: Personal Access Tokens
   Generate token (starts with kpat_)
   ```

2. **Add GitHub Secret**
   ```
   Repository → Settings → Secrets and variables → Actions
   New secret: KONNECT_PAT = your_token
   ```

## Deploy Service Catalog

1. **Start Local Environment**
   ```bash
   ./start_demo.sh
   ```
   This auto-generates `terraform/terraform.tfvars` with ngrok URL

2. **Commit & Push**
   ```bash
   git add terraform/terraform.tfvars
   git commit -m "Update Konnect deployment"
   git push origin main
   ```

3. **Verify Deployment**
   - GitHub: Actions tab → "Kong Konnect Deployment" workflow
   - Konnect: https://cloud.konghq.com → Service Hub → Services

## What Gets Deployed

```
Control Plane: FHIR Patient Records Control Plane
Service: Patient Records API
Tags: FHIR, Healthcare, Patient Data
Region: AU (Australia)
Upstream: Your ngrok URL
```

## Files Overview

| File | Purpose | Auto-Generated? |
|------|---------|----------------|
| `terraform/provider.tf` | Konnect provider config | ✗ Manual |
| `terraform/variables.tf` | Variable definitions | ✗ Manual |
| `terraform/terraform.tfvars` | Variable values | ✅ Yes (start_demo.sh) |
| `terraform/control_plane.tf` | Control plane resource | ✗ Manual |
| `terraform/service.tf` | Service & catalog | ✗ Manual |
| `terraform/outputs.tf` | Output definitions | ✗ Manual |
| `.github/workflows/konnect-deploy.yml` | Deployment workflow | ✗ Manual |

## Common Commands

```bash
# Start everything + generate Terraform vars
./start_demo.sh

# Stop everything
./stop_demo.sh

# View generated Terraform variables
cat terraform/terraform.tfvars

# Check workflow status
# Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/actions

# View Kong Konnect dashboard
# Go to: https://cloud.konghq.com
```

## Workflow Triggers

The deployment workflow runs when:
- You push to `main` branch
- Changes are made to `terraform/**`
- Changes are made to `.insomnia/fhir-api-openapi.yaml`
- Changes are made to `.github/workflows/konnect-deploy.yml`
- You manually trigger it (Actions tab → Kong Konnect Deployment → Run workflow)

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Authentication failed | Check KONNECT_PAT secret is set |
| Invalid ngrok URL | Run `./start_demo.sh` again |
| Service not visible | Check workflow logs, verify PAT permissions |
| Terraform state conflicts | Don't run `terraform apply` locally |

## Next Steps

- ✅ Service Catalog deployed
- ⏳ Configure Dev Portal (waiting for portal URL)
- ⏳ Add Routes (separate workflow - future)
- ⏳ Add Plugins (separate workflow - future)

## Documentation

- [KONNECT-SETUP.md](KONNECT-SETUP.md) - Detailed setup guide
- [KONNECT-IMPLEMENTATION.md](KONNECT-IMPLEMENTATION.md) - Implementation details
- [README.md](README.md) - Main project documentation
