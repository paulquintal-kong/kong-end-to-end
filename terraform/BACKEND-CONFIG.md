# Terraform Backend Configuration

This project supports both AWS S3 and Azure Storage backends for Terraform state management.

## Backend Options

### 1. AWS S3 Backend

**Prerequisites:**
- AWS account with S3 bucket created
- AWS credentials configured

**Setup:**

1. Create S3 bucket:
```bash
aws s3 mb s3://kong-fhir-tfstate --region ap-southeast-2
```

2. Enable versioning:
```bash
aws s3api put-bucket-versioning \
  --bucket kong-fhir-tfstate \
  --versioning-configuration Status=Enabled
```

3. Configure AWS credentials:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-2"
```

**Backend Configuration File:** `backend-aws.tfbackend`

### 2. Azure Storage Backend

**Prerequisites:**
- Azure account with Storage Account created
- Azure credentials configured

**Setup:**

1. Create resource group and storage account:
```bash
az group create --name kong-terraform-state --location australiaeast

az storage account create \
  --resource-group kong-terraform-state \
  --name kongfhirtfstate \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name tfstate \
  --account-name kongfhirtfstate
```

2. Get storage account key:
```bash
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group kong-terraform-state \
  --account-name kongfhirtfstate \
  --query '[0].value' -o tsv)
```

3. Configure Azure credentials:
```bash
export ARM_ACCESS_KEY="$ACCOUNT_KEY"
```

Alternatively, use Azure CLI authentication:
```bash
az login
```

**Backend Configuration File:** `backend-azure.tfbackend`

## Using the Backend

### During Demo Execution

When running `demo.sh` scripts, you'll be prompted to select a backend:

```
📦 Select Terraform backend:
   1) AWS S3
   2) Azure Storage
Choose backend (1 or 2):
```

### Manual Terraform Commands

To initialize Terraform manually with a specific backend:

**AWS S3:**
```bash
terraform init -backend-config=backend-aws.tfbackend -reconfigure
```

**Azure Storage:**
```bash
terraform init -backend-config=backend-azure.tfbackend -reconfigure
```

### Switching Backends

If you need to switch from one backend to another:

1. Run terraform init with the new backend config and `-reconfigure` flag:
```bash
terraform init -backend-config=backend-azure.tfbackend -reconfigure
```

2. Optionally migrate state from old backend to new:
```bash
terraform init -backend-config=backend-azure.tfbackend -migrate-state
```

## Backend Configuration Files

Each stage has its own backend configuration files:

- `stage1-platform/backend-aws.tfbackend`
- `stage1-platform/backend-azure.tfbackend`
- `stage2-integration/backend-aws.tfbackend`
- `stage2-integration/backend-azure.tfbackend`

You can customize these files to match your infrastructure:

**AWS Example (backend-aws.tfbackend):**
```hcl
bucket = "kong-fhir-tfstate"
key    = "stage1-platform/terraform.tfstate"
region = "ap-southeast-2"
```

**Azure Example (backend-azure.tfbackend):**
```hcl
resource_group_name  = "kong-terraform-state"
storage_account_name = "kongfhirtfstate"
container_name       = "tfstate"
key                  = "stage1-platform/terraform.tfstate"
```

## Best Practices

1. **Enable State Locking:** 
   - AWS: Use DynamoDB table for state locking
   - Azure: State locking is automatic with Azure Storage

2. **Enable Versioning:**
   - AWS: Enable S3 bucket versioning
   - Azure: Enable soft delete on storage account

3. **Secure Credentials:**
   - Use environment variables or credential management tools
   - Never commit credentials to version control
   - Use IAM roles or managed identities when possible

4. **Encryption:**
   - AWS: Enable server-side encryption on S3 bucket
   - Azure: Encryption is enabled by default

## Troubleshooting

### AWS S3 Issues

**Error: "No valid credential sources found"**
- Ensure AWS credentials are configured: `aws configure` or export environment variables
- Verify bucket exists: `aws s3 ls s3://kong-fhir-tfstate`

**Error: "Access Denied"**
- Check IAM permissions for S3 bucket access
- Verify bucket policy allows your user/role

### Azure Storage Issues

**Error: "storage account not found"**
- Verify storage account exists: `az storage account show --name kongfhirtfstate`
- Check resource group: `az group show --name kong-terraform-state`

**Error: "Authorization failed"**
- Set ARM_ACCESS_KEY or run `az login`
- Verify RBAC permissions on storage account

## Environment Variables Reference

### AWS
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_DEFAULT_REGION` - AWS region (default: ap-southeast-2)

### Azure
- `ARM_ACCESS_KEY` - Azure storage account access key
- Alternatively: Use Azure CLI authentication with `az login`

### Kong Konnect
- `KONNECT_TOKEN` - Kong Konnect personal access token (required)
