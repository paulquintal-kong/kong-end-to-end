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
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure

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
    CONTROL_PLANE_ID=$(terraform output -raw control_plane_id)
    CONTROL_PLANE_ENDPOINT=$(terraform output -raw control_plane_endpoint)
    echo "   Control Plane ID: $CONTROL_PLANE_ID"
    echo "   Control Plane Endpoint: $CONTROL_PLANE_ENDPOINT"
    echo ""
    
    # ========================================================================
    # Deploy Kong Gateway Data Plane
    # ========================================================================
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐵 Deploying Kong Gateway Data Plane"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check if docker-compose exists
    if [ -f "../../../docker-compose.yml" ]; then
        echo "📋 Updating Kong Gateway configuration..."
        
        # Extract control plane endpoints from Terraform output
        CP_ENDPOINT=$(echo "$CONTROL_PLANE_ENDPOINT" | sed 's|https://||')
        TELEMETRY_ENDPOINT=$(echo "$CP_ENDPOINT" | sed 's/\.cp0\./\.tp0\./')
        
        # Update docker-compose.yml with new control plane endpoints
        cd ../../..
        
        # Check if .kong directory exists (for certificates)
        if [ ! -d ".kong" ]; then
            echo "⚠️  Warning: .kong directory not found"
            echo "   You'll need to download cluster certificates from Konnect:"
            echo "   https://cloud.konghq.com/gateway-manager/$CONTROL_PLANE_ID/nodes"
            echo "   Save them to .kong/tls.crt and .kong/tls.key"
            echo ""
            read -p "Have you downloaded the certificates? (y/n): " certs_ready
            if [[ ! "$certs_ready" =~ ^[Yy]$ ]]; then
                echo "❌ Kong Gateway deployment skipped - certificates required"
                echo "   Run 'docker-compose up -d kong-gateway' after adding certificates"
                cd terraform/stages/1-platform
                echo ""
                echo "➡️  Next: cd ../2-integration && ./demo.sh"
                exit 0
            fi
        fi
        
        # Update docker-compose.yml with control plane endpoints
        echo "🔧 Configuring Kong Gateway to connect to: $CP_ENDPOINT"
        
        # Use sed to update the environment variables in docker-compose.yml
        sed -i.bak "s|KONG_CLUSTER_CONTROL_PLANE=.*|KONG_CLUSTER_CONTROL_PLANE=${CP_ENDPOINT}:443|" docker-compose.yml
        sed -i.bak "s|KONG_CLUSTER_SERVER_NAME=.*|KONG_CLUSTER_SERVER_NAME=${CP_ENDPOINT}|" docker-compose.yml
        sed -i.bak "s|KONG_CLUSTER_TELEMETRY_ENDPOINT=.*|KONG_CLUSTER_TELEMETRY_ENDPOINT=${TELEMETRY_ENDPOINT}:443|" docker-compose.yml
        sed -i.bak "s|KONG_CLUSTER_TELEMETRY_SERVER_NAME=.*|KONG_CLUSTER_TELEMETRY_SERVER_NAME=${TELEMETRY_ENDPOINT}|" docker-compose.yml
        
        echo "✓ docker-compose.yml updated"
        
        # Start Kong Gateway
        echo ""
        echo "🚀 Starting Kong Gateway Data Plane..."
        if docker-compose up -d kong-gateway; then
            echo "✓ Kong Gateway started"
            echo ""
            echo "📊 Checking connection status..."
            sleep 5
            
            # Check if gateway is running
            if docker ps | grep -q kong-dataplane; then
                echo "✓ Kong Gateway container is running"
                echo "  Proxy port: http://localhost:8000"
                echo ""
                echo "  Verify in Konnect:"
                echo "  https://cloud.konghq.com/gateway-manager/$CONTROL_PLANE_ID/nodes"
            else
                echo "⚠️  Kong Gateway container not running - check logs:"
                echo "  docker logs kong-dataplane"
            fi
        else
            echo "❌ Failed to start Kong Gateway"
            echo "   Check logs: docker logs kong-dataplane"
        fi
        
        cd terraform/stages/1-platform
    else
        echo "⚠️  docker-compose.yml not found - skipping Kong Gateway deployment"
    fi
    
    echo ""
    echo "➡️  Next: cd ../2-integration && ./demo.sh"
else
    echo "❌ Cancelled"
fi
