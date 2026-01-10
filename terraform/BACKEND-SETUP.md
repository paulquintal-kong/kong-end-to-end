# Terraform Backend Configuration - Quick Reference

## Summary

All Terraform stages now support **flexible backend configuration** for both AWS S3 and Azure Storage. No local backend is used.

## Files Created

### Backend Configuration Files

| Stage | AWS Backend | Azure Backend |
|-------|-------------|---------------|
| Stage 1 (Platform) | `1-platform/backend-aws.tfbackend` | `1-platform/backend-azure.tfbackend` |
| Stage 2 (Integration) | `2-integration/backend-aws.tfbackend` | `2-integration/backend-azure.tfbackend` |
| Stage 4 (API Product) | `4-api-product/backend-aws.tfbackend` | `4-api-product/backend-azure.tfbackend` |
| Stage 5 (Dev Portal) | `5-developer-portal/backend-aws.tfbackend` | `5-developer-portal/backend-azure.tfbackend` |

### Modified Files

| File | Changes |
|------|---------|
| `1-platform/provider.tf` | Updated to use partial backend configuration |
| `2-integration/provider.tf` | Updated to use partial backend configuration |
| `4-api-product/provider.tf` | Updated to use partial backend configuration |
| `5-developer-portal/provider.tf` | Updated to use partial backend configuration |
| `1-platform/demo.sh` | Added backend selection prompt |
| `2-integration/demo.sh` | Added backend selection prompt |
| `4-api-product/demo.sh` | Added backend selection prompt |
| `5-developer-portal/demo.sh` | Added backend selection prompt |

## How It Works

### 1. User Experience

When running any `demo.sh` script, users are prompted to select their backend:

```bash
📦 Select Terraform backend:
   1) AWS S3
   2) Azure Storage
Choose backend (1 or 2):
```

### 2. Backend Initialization

The selected backend configuration is passed to Terraform:

```bash
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure
```

Where `$BACKEND_CONFIG` is either:
- `backend-aws.tfbackend` (for AWS S3)
- `backend-azure.tfbackend` (for Azure Storage)

### 3. State Storage Locations

**AWS S3:**
- Bucket: `kong-fhir-tfstate`
- Region: `ap-southeast-2`
- Keys:
  - `stage1-platform/terraform.tfstate`
  - `stage2-integration/terraform.tfstate`
  - `stage4-api-product/terraform.tfstate`
  - `stage5-developer-portal/terraform.tfstate`

**Azure Storage:**
- Resource Group: `kong-terraform-state`
- Storage Account: `kongfhirtfstate`
- Container: `tfstate`
- Keys: (same as AWS)

## Setup Instructions

### Option 1: AWS S3 Backend

```bash
# Create S3 bucket
aws s3 mb s3://kong-fhir-tfstate --region ap-southeast-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket kong-fhir-tfstate \
  --versioning-configuration Status=Enabled

# Set credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-2"
```

### Option 2: Azure Storage Backend

```bash
# Create resources
az group create --name kong-terraform-state --location australiaeast

az storage account create \
  --resource-group kong-terraform-state \
  --name kongfhirtfstate \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name tfstate \
  --account-name kongfhirtfstate

# Set credentials
export ARM_ACCESS_KEY=$(az storage account keys list \
  --resource-group kong-terraform-state \
  --account-name kongfhirtfstate \
  --query '[0].value' -o tsv)
```

## Benefits

✅ **Flexibility**: Choose between AWS or Azure based on your infrastructure  
✅ **No Local State**: All state is stored remotely for team collaboration  
✅ **State Locking**: Built-in support for concurrent operations  
✅ **Versioning**: State history maintained by cloud provider  
✅ **Security**: Credentials managed via environment variables  
✅ **Consistency**: Same backend choice across all stages

## Customization

To use different bucket/account names, edit the `*.tfbackend` files:

**AWS Example:**
```hcl
bucket = "my-custom-bucket"
key    = "my-app/terraform.tfstate"
region = "us-east-1"
```

**Azure Example:**
```hcl
resource_group_name  = "my-resource-group"
storage_account_name = "mycustomstorage"
container_name       = "tfstate"
key                  = "my-app/terraform.tfstate"
```

## Documentation

Full setup instructions and troubleshooting: [BACKEND-CONFIG.md](BACKEND-CONFIG.md)
