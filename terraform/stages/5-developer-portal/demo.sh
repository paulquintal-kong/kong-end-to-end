#!/bin/bash
# ========================================================================
# Stage 4 Demo Script: API Owner (Developer Portal)
# ========================================================================
set -e

echo "=========================================="
echo "STAGE 4: API OWNER - DEVELOPER PORTAL"
echo "Publishing for External Developers"
echo "=========================================="
echo ""

# Check for token
if [ -z "$KONNECT_TOKEN" ]; then
    echo "❌ Error: KONNECT_TOKEN environment variable not set"
    exit 1
fi

cd "$(dirname "$0")"

# Load previous outputs
if [ ! -f "../stage3-outputs.json" ]; then
    echo "❌ Error: Stage 3 outputs not found"
    echo "   Run Stage 3 first: cd ../3-api-product && ./demo.sh"
    exit 1
fi

CATALOG_API_ID=$(jq -r '.catalog_api_id.value' ../stage3-outputs.json)

echo "📥 Using Catalog API ID from Stage 3: $CATALOG_API_ID"
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

# Portal configuration options
echo "🎛️  Portal Configuration Options:"
echo ""
read -p "   Enable authentication? (yes/no) [no]: " enable_auth
enable_auth=${enable_auth:-no}
enable_auth_bool=$([ "$enable_auth" = "yes" ] && echo "true" || echo "false")

if [ "$enable_auth" = "yes" ]; then
    read -p "   Auto-approve developers? (yes/no) [no]: " auto_approve
    auto_approve=${auto_approve:-no}
    auto_approve_bool=$([ "$auto_approve" = "yes" ] && echo "true" || echo "false")
else
    auto_approve_bool="false"
fi

# Create terraform.tfvars
echo ""
echo "📝 Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
konnect_token           = "$KONNECT_TOKEN"
catalog_api_id          = "$CATALOG_API_ID"
portal_name             = "Patient Records API"
portal_display_name     = "Developer Portal"
enable_auth             = $enable_auth_bool
auto_approve_developers = $auto_approve_bool
EOF

# Initialize
echo ""
echo "🔧 Initializing Terraform..."
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure

# Plan
echo ""
echo "📋 Planning developer portal..."
terraform plan

# Apply
echo ""
read -p "🚀 Apply these changes? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Stage 4 Complete!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 DEVELOPER PORTAL IS LIVE!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    terraform output developer_onboarding_message
    
    PORTAL_URL=$(terraform output -raw portal_url)
    echo "🌐 Opening portal in browser..."
    sleep 2
    open "$PORTAL_URL" 2>/dev/null || xdg-open "$PORTAL_URL" 2>/dev/null || echo "   Visit: $PORTAL_URL"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎬 DEMO COMPLETE - ALL STAGES DEPLOYED!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "❌ Cancelled"
fi
