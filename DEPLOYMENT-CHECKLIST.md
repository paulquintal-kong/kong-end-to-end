# Deployment Checklist

## Pre-Deployment ✅

- [x] Azure CLI installed and logged in
- [x] GitHub CLI installed and authenticated
- [x] Azure Storage account created (`quintalconsultingtfstate`)
- [x] Azure container created (`kong-fhir-tfstate`)
- [x] Service principal created (`github-kong-fhir-terraform`)
- [x] GitHub Dev environment created
- [x] GitHub environment secrets configured (5 secrets)
- [x] GitHub environment variables configured (3 variables)
- [x] Terraform backend configuration created (`terraform/backend.tf`)
- [x] GitHub Actions workflow updated for Azure backend

## Ready to Deploy

### Step 1: Start Local Environment

```bash
./start_demo.sh
```

**Verify:**
- [ ] HAPI FHIR server running on http://localhost:8080/fhir
- [ ] Ngrok tunnel created
- [ ] File `terraform/terraform.tfvars` generated with ngrok URL
- [ ] File `.ngrok-url.txt` contains tunnel URL

### Step 2: Commit Changes

```bash
git add terraform/backend.tf
git add terraform/terraform.tfvars
git add .github/workflows/konnect-deploy.yml
git add AZURE-GITHUB-SETUP.md
git add SETUP-SUMMARY.md
git add DEPLOYMENT-CHECKLIST.md
git commit -m "Configure Azure backend and GitHub Dev environment"
git push origin main
```

**Verify:**
- [ ] Files committed successfully
- [ ] Pushed to main branch

### Step 3: Monitor GitHub Actions

Go to: https://github.com/paulquintal-kong/kong-end-to-end/actions

**Workflow: Kong Konnect Deployment**

Expected steps:
- [ ] Checkout code
- [ ] Azure Login
- [ ] Setup Terraform
- [ ] Terraform Format Check
- [ ] Terraform Init (connects to Azure backend)
- [ ] Terraform Validate
- [ ] Terraform Plan
- [ ] Terraform Apply
- [ ] Generate Deployment Report

### Step 4: Verify Azure State Storage

```bash
# List state files in Azure
az storage blob list \
  --container-name kong-fhir-tfstate \
  --account-name quintalconsultingtfstate \
  --auth-mode login \
  --output table
```

**Verify:**
- [ ] `kong-fhir.tfstate` file exists in Azure
- [ ] State file size is > 0 bytes

### Step 5: Verify Kong Konnect Deployment

1. Login to Kong Konnect: https://cloud.konghq.com
2. Navigate to **Service Hub** → **Services**

**Verify:**
- [ ] Control Plane: "FHIR Patient Records Control Plane" exists
- [ ] Service: "Patient Records API" exists
- [ ] Service has correct tags: FHIR, Healthcare, Patient Data
- [ ] Service upstream points to ngrok URL
- [ ] Service catalog documentation is complete

### Step 6: Test the Deployment

```bash
# View Terraform outputs
cd terraform
terraform output

# Expected outputs:
# - control_plane_id
# - control_plane_name
# - control_plane_endpoint
# - service_id
# - service_name
# - service_url
```

**Verify:**
- [ ] All outputs are populated
- [ ] Service URL matches ngrok URL

## Post-Deployment

### Verify GitHub Actions Summary

Check the workflow summary for:
- [ ] Deployment status: ✅ Successfully deployed
- [ ] Environment: Dev
- [ ] Terraform State: Azure Storage
- [ ] All outputs displayed

### Test FHIR API Through Kong (Future)

Once routes are configured:

```bash
# Test through Kong Gateway
curl -X GET \
  "https://<kong-gateway-url>/fhir/Patient/patient-1013" \
  -H "Accept: application/fhir+json"
```

## Troubleshooting

### Issue: Terraform Init Fails

**Check:**
```bash
# Verify Azure login
az account show

# Test storage access
az storage container show \
  --name kong-fhir-tfstate \
  --account-name quintalconsultingtfstate \
  --auth-mode login
```

**Solution:**
- Ensure Azure credentials are valid
- Verify service principal has access to storage account

### Issue: GitHub Actions Authentication Fails

**Check GitHub Secrets:**
```bash
gh api repos/paulquintal-kong/kong-end-to-end/environments/Dev/secrets | jq '.secrets[] | .name'
```

**Expected Secrets:**
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET
- AZURE_SUBSCRIPTION_ID
- AZURE_TENANT_ID
- KONNECT_PAT

**Solution:**
- Verify all secrets are set
- Check service principal credentials haven't expired

### Issue: Terraform Apply Fails

**Check Logs:**
1. Go to GitHub Actions workflow
2. Check "Terraform Apply" step logs
3. Look for error messages

**Common Issues:**
- Kong Konnect PAT token invalid or expired
- Ngrok URL not accessible
- Service already exists (state mismatch)

**Solution:**
```bash
# Verify Kong Konnect token
# (Token should start with kpat_)

# Verify ngrok URL is accessible
curl -I https://asia-bosker-renna.ngrok-free.dev/fhir/metadata
```

### Issue: State Lock Error

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
# Force unlock (use with caution)
cd terraform
terraform force-unlock <LOCK_ID>
```

## Rollback Procedure

If deployment fails and needs to be rolled back:

### Option 1: Revert Git Commit

```bash
git revert HEAD
git push origin main
```

### Option 2: Destroy Resources via Terraform

```bash
cd terraform
terraform destroy

# Then re-apply with fixed configuration
terraform apply
```

### Option 3: Manual Cleanup

1. Delete service from Kong Konnect dashboard
2. Delete control plane from Kong Konnect dashboard
3. Clear Terraform state:
```bash
terraform state list
terraform state rm <resource_name>
```

## Success Criteria

Deployment is successful when:

- [x] GitHub Actions workflow completes without errors
- [x] Terraform state stored in Azure Storage
- [x] Control plane visible in Kong Konnect
- [x] Service visible in Service Catalog
- [x] Service documentation complete
- [x] Terraform outputs match expected values
- [x] No errors in workflow logs

## Next Steps After Successful Deployment

1. Configure routes in separate workflow
2. Configure plugins (rate limiting, auth, etc.)
3. Enable Dev Portal integration
4. Set up monitoring and alerts
5. Configure production environment

## Contact & Support

For issues or questions:
- GitHub Issues: https://github.com/paulquintal-kong/kong-end-to-end/issues
- Email: healthcare-team@example.com (from service catalog)

## Documentation References

- [SETUP-SUMMARY.md](SETUP-SUMMARY.md) - Quick summary of what was configured
- [AZURE-GITHUB-SETUP.md](AZURE-GITHUB-SETUP.md) - Detailed Azure and GitHub setup
- [KONNECT-SETUP.md](KONNECT-SETUP.md) - Kong Konnect deployment guide
- [KONNECT-IMPLEMENTATION.md](KONNECT-IMPLEMENTATION.md) - Implementation details
- [README.md](README.md) - Main project documentation
