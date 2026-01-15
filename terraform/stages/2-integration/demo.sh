#!/bin/bash
# ========================================================================
# Stage 2 Demo Script: Integration Engineer
# ========================================================================
set -e

echo "=========================================="
echo "STAGE 2: INTEGRATION ENGINEER"
echo "Configuring Gateway Services & Routes"
echo "=========================================="
echo ""

# Check for token
if [ -z "$KONNECT_TOKEN" ]; then
    echo "❌ Error: KONNECT_TOKEN environment variable not set"
    exit 1
fi

cd "$(dirname "$0")"

# Load Stage 1 outputs
if [ ! -f "../stage1-outputs.json" ]; then
    echo "❌ Error: Stage 1 outputs not found"
    echo "   Run Stage 1 first: cd ../1-platform && ./demo.sh"
    exit 1
fi

CONTROL_PLANE_ID=$(jq -r '.control_plane_id.value' ../stage1-outputs.json)

echo "📥 Using Control Plane ID from Stage 1: $CONTROL_PLANE_ID"
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

# Prompt for upstream URL
read -p "🔗 Enter your backend API URL (or press Enter for default): " upstream_url
upstream_url=${upstream_url:-"https://asia-bosker-renna.ngrok-free.dev/fhir"}

# Create terraform.tfvars
echo "📝 Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
konnect_token    = "$KONNECT_TOKEN"
control_plane_id = "$CONTROL_PLANE_ID"
upstream_url     = "$upstream_url"
EOF

# Initialize
echo ""
echo "🔧 Initializing Terraform..."
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure

# Plan
echo ""
echo "📋 Planning gateway configuration..."
terraform plan

# Apply
echo ""
read -p "🚀 Apply these changes? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Stage 2 Complete!"
    echo ""
    echo "📤 Outputs for Stage 3:"
    terraform output -json > ../stage2-outputs.json
    SERVICE_ID=$(terraform output -raw service_id)
    API_ENDPOINT=$(terraform output -raw api_endpoint)
    echo "   Service ID: $SERVICE_ID"
    echo "   API Endpoint: $API_ENDPOINT"
    
    # Update demo state file
    if [ -f "../../.demo-state.json" ]; then
        echo ""
        echo "📝 Updating .demo-state.json..."
        jq --arg service_id "$SERVICE_ID" \
           '.service_id = $service_id | .updated_at = now | strftime("%Y-%m-%dT%H:%M:%SZ")' \
           ../../.demo-state.json > ../../.demo-state.json.tmp && \
        mv ../../.demo-state.json.tmp ../../.demo-state.json
        echo "   ✓ Updated service_id"
    fi
    
    echo ""
    echo "🧪 Test the API:"
    echo "   curl $API_ENDPOINT"
    echo ""
    echo "➡️  Next: cd ../4-api-product && ./demo.sh"
else
    echo "❌ Cancelled"
fi
