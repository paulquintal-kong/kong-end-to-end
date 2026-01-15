#!/bin/bash
# ========================================================================
# Stage 5 Demo Script: API Owner (Developer Portal)
# ========================================================================
set -e

echo "=========================================="
echo "STAGE 5: API OWNER - DEVELOPER PORTAL"
echo "Publishing API to Developer Portal"
echo "=========================================="
echo ""

# Check for token
if [ -z "$KONNECT_TOKEN" ]; then
    echo "❌ Error: KONNECT_TOKEN environment variable not set"
    exit 1
fi

cd "$(dirname "$0")"

# Load previous outputs
if [ ! -f "../stage4-outputs.json" ]; then
    echo "❌ Error: Stage 4 outputs not found"
    echo "   Run Stage 4 first: cd ../4-api-product && ./demo.sh"
    exit 1
fi

CATALOG_API_ID=$(jq -r '.catalog_api_id.value' ../stage4-outputs.json)

echo "📥 Using Catalog API ID from Stage 4: $CATALOG_API_ID"
echo ""

# Load portal ID from demo state or detect from API
PORTAL_ID=""
if [ -f "../../.demo-state.json" ]; then
    PORTAL_ID=$(jq -r '.portal_id // empty' ../../.demo-state.json)
    if [ -n "$PORTAL_ID" ] && [ "$PORTAL_ID" != "null" ]; then
        echo "📋 Found Portal ID in .demo-state.json: $PORTAL_ID"
    fi
fi

# Check for existing portal if not in demo state
if [ -z "$PORTAL_ID" ] || [ "$PORTAL_ID" = "null" ]; then
    echo "🔍 Checking for existing Developer Portal..."
    PORTALS=$(curl -s -X GET "https://au.api.konghq.com/v3/portals" \
      -H "Authorization: Bearer $KONNECT_TOKEN" \
      -H "Content-Type: application/json")

    PORTALS=$(curl -s -X GET "https://au.api.konghq.com/v3/portals" \
      -H "Authorization: Bearer $KONNECT_TOKEN" \
      -H "Content-Type: application/json")

    PORTAL_COUNT=$(echo "$PORTALS" | jq '.data | length')

    if [ "$PORTAL_COUNT" -eq 0 ]; then
        echo ""
        echo "❌ No Developer Portal found in your Konnect organization"
        echo ""
        echo "Please create a Developer Portal first:"
        echo "  1. Go to https://au.cloud.konghq.com/portals"
        echo "  2. Click 'New Portal'"
        echo "  3. Configure your portal settings"
        echo "  4. Re-run this script"
        echo ""
        exit 1
    fi

    echo "✓ Found $PORTAL_COUNT portal(s)"
    echo ""
    echo "Available Portals:"
    echo "$PORTALS" | jq -r '.data[] | "  - \(.name) (ID: \(.id))"'
    echo ""

    # Prompt for portal ID or use first one
    if [ "$PORTAL_COUNT" -eq 1 ]; then
        PORTAL_ID=$(echo "$PORTALS" | jq -r '.data[0].id')
        PORTAL_NAME=$(echo "$PORTALS" | jq -r '.data[0].name')
        echo "Using portal: $PORTAL_NAME ($PORTAL_ID)"
    else
        echo "Multiple portals found. Please select one:"
        read -p "Enter Portal ID (or press Enter for first portal): " input_portal_id
        if [ -z "$input_portal_id" ]; then
            PORTAL_ID=$(echo "$PORTALS" | jq -r '.data[0].id')
        else
            PORTAL_ID="$input_portal_id"
        fi
    fi
    
    # Update demo state with portal ID
    if [ -f "../../.demo-state.json" ]; then
        echo "📝 Updating .demo-state.json with portal_id..."
        jq --arg portal_id "$PORTAL_ID" \
           '.portal_id = $portal_id | .updated_at = now | strftime("%Y-%m-%dT%H:%M:%SZ")' \
           ../../.demo-state.json > ../../.demo-state.json.tmp && \
        mv ../../.demo-state.json.tmp ../../.demo-state.json
    fi
fi
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

# Create terraform.tfvars with values from previous stages
echo ""
echo "📝 Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
# Auto-generated from demo state and previous stage outputs
konnect_token  = "$KONNECT_TOKEN"
catalog_api_id = "$CATALOG_API_ID"
portal_id      = "$PORTAL_ID"

# Portal configuration (reference only - portal already configured)
portal_name         = "Patient Records API"
portal_display_name = "Developer Portal"
enable_auth         = false
auto_approve_developers = false
EOF

echo "✓ terraform.tfvars created with:"
echo "   catalog_api_id = $CATALOG_API_ID"
echo "   portal_id = $PORTAL_ID"
echo ""

# Initialize
echo ""
echo "🔧 Initializing Terraform..."
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure

# Plan
echo ""
echo "📋 Planning API publication to portal..."
terraform plan

# Apply
echo ""
read -p "🚀 Publish API to portal? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Stage 5 Complete!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 API PUBLISHED TO DEVELOPER PORTAL!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    terraform output developer_onboarding_message
    
    # Save outputs
    terraform output -json > ../stage5-outputs.json
    echo "📁 Outputs saved to: ../stage5-outputs.json"
    
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
