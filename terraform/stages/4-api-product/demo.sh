#!/bin/bash
# ========================================================================
# Stage 3 Demo Script: API Owner (Productization)
# ========================================================================
set -e

echo "=========================================="
echo "STAGE 3: API OWNER - PRODUCTIZATION"
echo "Publishing to Catalog & Governance"
echo "=========================================="
echo ""

# Check for token
if [ -z "$KONNECT_TOKEN" ]; then
    echo "❌ Error: KONNECT_TOKEN environment variable not set"
    exit 1
fi

cd "$(dirname "$0")"

# Load previous outputs
if [ ! -f "../stage1-outputs.json" ] || [ ! -f "../stage2-outputs.json" ]; then
    echo "❌ Error: Previous stage outputs not found"
    echo "   Run Stages 1 and 2 first"
    exit 1
fi

CONTROL_PLANE_ID=$(jq -r '.control_plane_id.value' ../stage1-outputs.json)
SERVICE_ID=$(jq -r '.service_id.value' ../stage2-outputs.json)

echo "📥 Using outputs from previous stages:"
echo "   Control Plane: $CONTROL_PLANE_ID"
echo "   Service: $SERVICE_ID"
echo ""

# Backend selection
echo "📦 Select Terraform backend:"
echo "   1) AWS S3"
echo "   2) Azure Storage"
read -p "Choose backend (1 or 2): " backend_choice

case $backend_choice in
    1)
        BACKEND_CONFIG="backend-aws.tfbackend"
        echo "✓ Using AWS S3 backend"
        echo "  Ensure AWS credentials are configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
        ;;
    2)
        BACKEND_CONFIG="backend-azure.tfbackend"
        echo "✓ Using Azure Storage backend"
        echo "  Ensure Azure credentials are configured (ARM_ACCESS_KEY or Azure CLI)"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
echo ""

# Prompt for rate limit
read -p "🚦 API Rate Limit (requests per minute) [default: 5]: " rate_limit
rate_limit=${rate_limit:-5}

# Create terraform.tfvars
echo "📝 Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
konnect_token         = "$KONNECT_TOKEN"
control_plane_id      = "$CONTROL_PLANE_ID"
service_id            = "$SERVICE_ID"
rate_limit_per_minute = $rate_limit
EOF

# Initialize
echo ""
echo "🔧 Initializing Terraform..."
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure

# Plan
echo ""
echo "📋 Planning API productization..."
terraform plan

# Apply
echo ""
read -p "🚀 Apply these changes? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Stage 3 Complete!"
    echo ""
    echo "📤 Outputs for Stage 4:"
    terraform output -json > ../stage3-outputs.json
    echo "   Catalog API ID: $(terraform output -raw catalog_api_id)"
    echo "   Rate Limit: $rate_limit requests/minute"
    echo ""
    echo "🔍 View in Kong Konnect:"
    echo "   Catalog: https://au.cloud.konghq.com/us/catalog"
    echo ""
    echo "🧪 Test Rate Limiting:"
    echo "   Run this 6 times to trigger rate limit:"
    API_ENDPOINT=$(jq -r '.api_endpoint.value' ../stage2-outputs.json)
    echo "   curl $API_ENDPOINT"
    echo ""
    echo "➡️  Next: cd ../4-developer-portal && ./demo.sh"
else
    echo "❌ Cancelled"
fi
