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
terraform init

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
    echo "   Service ID: $(terraform output -raw service_id)"
    echo "   API Endpoint: $(terraform output -raw api_endpoint)"
    echo ""
    echo "🧪 Test the API:"
    echo "   curl $(terraform output -raw api_endpoint)"
    echo ""
    echo "➡️  Next: cd ../3-api-product && ./demo.sh"
else
    echo "❌ Cancelled"
fi
