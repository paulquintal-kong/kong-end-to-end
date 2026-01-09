#!/bin/bash
# ========================================================================
# Stage 1 Demo Script: Platform Engineer
# ========================================================================
set -e

echo "=========================================="
echo "STAGE 1: PLATFORM ENGINEER"
echo "Setting up Kong Gateway Infrastructure"
echo "=========================================="
echo ""

# Check for token
if [ -z "$KONNECT_TOKEN" ]; then
    echo "❌ Error: KONNECT_TOKEN environment variable not set"
    echo "   Run: export KONNECT_TOKEN='your-token'"
    exit 1
fi

cd "$(dirname "$0")"

# Create terraform.tfvars
echo "📝 Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
konnect_token = "$KONNECT_TOKEN"
environment   = "production"
project_name  = "fhir-patient-records"
EOF

# Initialize Terraform
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Plan
echo ""
echo "📋 Planning infrastructure changes..."
terraform plan

# Apply
echo ""
read -p "🚀 Apply these changes? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Stage 1 Complete!"
    echo ""
    echo "📤 Outputs for Stage 2:"
    terraform output -json > ../stage1-outputs.json
    echo "   Control Plane ID: $(terraform output -raw control_plane_id)"
    echo ""
    echo "➡️  Next: cd ../2-integration && ./demo.sh"
else
    echo "❌ Cancelled"
fi
