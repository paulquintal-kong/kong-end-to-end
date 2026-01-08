# Azure and GitHub Environment Configuration

## Summary

Successfully configured Azure backend for Terraform state management and GitHub environment variables for the Kong FHIR API project.

## Azure Configuration

### Resource Details

- **Subscription**: Azure subscription (18d9a473-fdce-4f7e-a3c0-a62fb9e1bbba)
- **Account**: paul_quintal@hotmail.com
- **Region**: Australia East

### Terraform State Storage

- **Resource Group**: `tfstate-rg`
- **Storage Account**: `quintalconsultingtfstate`
- **Container**: `kong-fhir-tfstate`
- **State File**: `kong-fhir.tfstate`

### Service Principal

Created service principal for GitHub Actions authentication:

- **Name**: github-kong-fhir-terraform
- **Client ID**: 9f411afd-b182-47f1-ad24-397f8cccf156
- **Role**: Contributor
- **Scope**: /subscriptions/18d9a473-fdce-4f7e-a3c0-a62fb9e1bbba/resourceGroups/tfstate-rg

## GitHub Configuration

### Environment

- **Name**: Dev
- **Repository**: paulquintal-kong/kong-end-to-end

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `FHIR_PATIENT_ID` | patient-1013 | Test patient ID for API tests |
| `FHIR_BASE_PATH` | /fhir | FHIR server base path |
| `FHIR_SCHEME` | https | URL scheme for FHIR server |

### Environment Secrets

| Secret | Purpose |
|--------|---------|
| `AZURE_CLIENT_ID` | Service principal client ID for Azure authentication |
| `AZURE_CLIENT_SECRET` | Service principal secret for Azure authentication |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_TENANT_ID` | Azure Active Directory tenant ID |
| `KONNECT_PAT` | Kong Konnect Personal Access Token |

## Terraform Backend Configuration

Created [terraform/backend.tf](terraform/backend.tf):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "quintalconsultingtfstate"
    container_name       = "kong-fhir-tfstate"
    key                  = "kong-fhir.tfstate"
  }
}
```

## GitHub Actions Workflow Updates

Updated [.github/workflows/konnect-deploy.yml](.github/workflows/konnect-deploy.yml) with:

1. **Environment**: Uses `Dev` environment for secrets and variables
2. **Azure Login**: Authenticates with Azure using service principal
3. **Terraform Backend**: All Terraform commands use Azure backend with ARM environment variables

### Authentication Flow

```
GitHub Actions Workflow
  ↓
Azure Login (using secrets)
  ↓
Terraform Init (connects to Azure Storage)
  ↓
Terraform Plan/Apply (state stored in Azure)
```

## Usage

### Local Development

When running Terraform locally:

```bash
cd terraform

# Login to Azure
az login

# Initialize Terraform (will configure Azure backend)
terraform init

# Plan changes
terraform plan

# Apply changes (optional - GitHub Actions will do this)
terraform apply
```

### CI/CD Pipeline

The workflow automatically:

1. Authenticates with Azure using service principal
2. Initializes Terraform with Azure backend
3. Plans and applies Terraform changes
4. Stores state in Azure Storage

## Verification

### Check GitHub Environment Configuration

```bash
# List environment variables
gh variable list --env Dev

# List environment secrets
gh secret list --env Dev
```

### Check Azure Resources

```bash
# Verify storage account
az storage account show --name quintalconsultingtfstate --resource-group tfstate-rg

# List containers
az storage container list --account-name quintalconsultingtfstate --auth-mode login

# Verify service principal
az ad sp list --display-name github-kong-fhir-terraform
```

### Test Terraform Backend

```bash
cd terraform

# Initialize (should connect to Azure)
terraform init

# You should see output like:
# Initializing the backend...
# Successfully configured the backend "azurerm"!
```

## Security Notes

- ✅ All sensitive credentials stored as GitHub environment secrets
- ✅ Service principal has minimal permissions (Contributor on tfstate-rg only)
- ✅ Terraform state encrypted at rest in Azure Storage
- ✅ Azure backend configured for state locking
- ⚠️ Service principal credentials shown once during creation (now stored in GitHub)

## Troubleshooting

### Issue: Terraform backend initialization fails

**Check:**
1. Azure credentials are correctly set in GitHub secrets
2. Service principal has access to storage account
3. Storage container exists

**Solution:**
```bash
# Verify Azure login
az account show

# Test storage access
az storage container show \
  --name kong-fhir-tfstate \
  --account-name quintalconsultingtfstate \
  --auth-mode login
```

### Issue: GitHub Actions cannot authenticate to Azure

**Check:**
1. All four Azure secrets are set: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID
2. Service principal credentials are correct
3. Service principal has not expired

**Solution:**
```bash
# Verify service principal
az ad sp show --id 9f411afd-b182-47f1-ad24-397f8cccf156

# Reset credentials if needed
az ad sp credential reset --id 9f411afd-b182-47f1-ad24-397f8cccf156
```

### Issue: Cannot access Terraform state

**Check:**
1. Storage account exists and is accessible
2. Container 'kong-fhir-tfstate' exists
3. Permissions are correctly set

**Solution:**
```bash
# List all state files
az storage blob list \
  --container-name kong-fhir-tfstate \
  --account-name quintalconsultingtfstate \
  --auth-mode login
```

## Next Steps

1. ✅ Azure backend configured
2. ✅ GitHub environment variables set
3. ✅ Service principal created
4. ✅ Workflow updated for Azure authentication
5. ⏳ Test deployment by pushing to main branch
6. ⏳ Verify state is stored in Azure after first deployment

## Commands Reference

### GitHub CLI

```bash
# List environments
gh api repos/paulquintal-kong/kong-end-to-end/environments

# Set environment variable
gh variable set VARIABLE_NAME --body "value" --env Dev

# Set environment secret
gh secret set SECRET_NAME --body "value" --env Dev

# List variables
gh variable list --env Dev

# List secrets
gh secret list --env Dev
```

### Azure CLI

```bash
# Login
az login

# Show current account
az account show

# List resource groups
az group list -o table

# List storage accounts
az storage account list --resource-group tfstate-rg -o table

# List containers
az storage container list --account-name quintalconsultingtfstate --auth-mode login

# Create service principal
az ad sp create-for-rbac --name "sp-name" --role contributor --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP
```

### Terraform

```bash
# Initialize with backend
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Show state
terraform state list

# Show backend configuration
terraform init -backend-config=""
```

## Documentation Links

- [Azure Backend for Terraform](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Azure Service Principals](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)
- [GitHub Actions Azure Login](https://github.com/Azure/login)
