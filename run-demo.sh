#!/bin/bash
set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Banner
echo -e "${BLUE}${BOLD}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════╗
║                    Kong Konnect End-to-End Demo                          ║
║                                                                          ║
║  Platform Engineering & API Product Management Demonstration             ║
║  Persona: Platform Engineer / API Product Manager                        ║
╚══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}This demo showcases the complete API lifecycle:${NC}"
echo "  1. Platform provisioning (Kong Gateway control plane)"
echo "  2. API gateway integration (upstream service connection)"
echo "  3. API specification testing (contract validation)"
echo "  4. API product creation (catalog & rate limiting)"
echo "  5. Developer portal publication (3rd party access)"
echo ""

# Check prerequisites
echo -e "${BOLD}Checking prerequisites...${NC}"
if ! command -v gh &> /dev/null; then
    echo -e "${RED}✗ GitHub CLI (gh) not found. Install: brew install gh${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform not found. Install: brew install terraform${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}✗ jq not found. Install: brew install jq${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Helper function to wait for workflow completion
wait_for_workflow() {
    local workflow_name=$1
    local max_attempts=60
    local attempt=0
    
    echo -e "${YELLOW}⏳ Waiting for workflow to complete...${NC}"
    
    while [ $attempt -lt $max_attempts ]; do
        sleep 5
        STATUS=$(gh run list -w "$workflow_name" -L 1 --json status,conclusion --jq '.[0]')
        CURRENT_STATUS=$(echo "$STATUS" | jq -r '.status')
        CONCLUSION=$(echo "$STATUS" | jq -r '.conclusion')
        
        if [ "$CURRENT_STATUS" = "completed" ]; then
            if [ "$CONCLUSION" = "success" ]; then
                echo -e "${GREEN}✓ Workflow completed successfully${NC}"
                return 0
            else
                echo -e "${RED}✗ Workflow failed with conclusion: $CONCLUSION${NC}"
                gh run list -w "$workflow_name" -L 1 --json url --jq '.[0].url' | xargs echo "View logs:"
                return 1
            fi
        fi
        
        attempt=$((attempt + 1))
        echo -ne "\r  Status: $CURRENT_STATUS (${attempt}s elapsed)"
    done
    
    echo -e "\n${RED}✗ Workflow timed out after ${max_attempts} seconds${NC}"
    return 1
}

# Stage 1: Platform
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Stage 1: Platform Provisioning${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Business Context:${NC}"
echo "  Setting up a dedicated API gateway control plane for the FHIR Patient Records"
echo "  system. This creates isolated infrastructure for managing healthcare APIs with"
echo "  proper governance, security policies, and compliance controls."
echo ""
echo -e "${YELLOW}Technical Actions:${NC}"
echo "  • Creating Kong Konnect control plane with Terraform"
echo "  • Configuring gateway policies and security settings"
echo "  • Establishing remote state management for multi-stage deployment"
echo ""
echo -e "${BOLD}Command:${NC} gh workflow run stage1-platform.yml"
echo ""
read -p "Press Enter to continue..."

gh workflow run stage1-platform.yml
wait_for_workflow "stage1-platform.yml" || exit 1

# Get control plane ID from terraform state
cd terraform/stages/1-platform
terraform init -backend-config=backend-azure.tfbackend -input=false > /dev/null 2>&1
CONTROL_PLANE_ID=$(terraform output -raw control_plane_id 2>/dev/null)
cd - > /dev/null

echo ""
echo -e "${GREEN}${BOLD}✓ Platform Ready${NC}"
echo -e "  Control Plane ID: ${BOLD}$CONTROL_PLANE_ID${NC}"
echo ""

# Stage 2: Integration
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Stage 2: API Gateway Integration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Business Context:${NC}"
echo "  Connecting the backend FHIR server to Kong Gateway. This creates a managed"
echo "  endpoint that provides centralized authentication, rate limiting, logging,"
echo "  and analytics for all API traffic to the healthcare records system."
echo ""
echo -e "${YELLOW}Technical Actions:${NC}"
echo "  • Registering upstream FHIR service (ngrok tunnel)"
echo "  • Creating Kong gateway service and route definitions"
echo "  • Configuring health checks and circuit breakers"
echo ""
echo -e "${BOLD}Command:${NC} gh workflow run stage2-integration.yml -f control_plane_id=$CONTROL_PLANE_ID"
echo ""
read -p "Press Enter to continue..."

gh workflow run stage2-integration.yml -f control_plane_id="$CONTROL_PLANE_ID"
wait_for_workflow "stage2-integration.yml" || exit 1

echo ""
echo -e "${GREEN}${BOLD}✓ Gateway Integration Complete${NC}"
echo -e "  Backend service registered and accessible via Kong Gateway"
echo ""

# Stage 3: API Spec Testing
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Stage 3: API Specification Testing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Business Context:${NC}"
echo "  Validating that the FHIR Patient API meets the OpenAPI specification contract."
echo "  This ensures API consumers receive consistent, well-documented responses that"
echo "  match the published schema, reducing integration errors and support tickets."
echo ""
echo -e "${YELLOW}Technical Actions:${NC}"
echo "  • Linting OpenAPI specification with Insomnia CLI"
echo "  • Running automated API tests against Patient endpoints"
echo "  • Validating response schemas and status codes"
echo ""
echo -e "${BOLD}Command:${NC} gh workflow run stage3-api-spec-testing.yml"
echo ""
read -p "Press Enter to continue..."

gh workflow run stage3-api-spec-testing.yml
wait_for_workflow "stage3-api-spec-testing.yml" || exit 1

echo ""
echo -e "${GREEN}${BOLD}✓ API Specification Validated${NC}"
echo -e "  OpenAPI contract compliance verified"
echo ""

# Stage 4: API Product
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Stage 4: API Product Catalog${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Business Context:${NC}"
echo "  Publishing the FHIR Patient API as a discoverable product in the Kong catalog."
echo "  This enables API governance teams to manage versioning, set consumption policies,"
echo "  and provide self-service access to developers with built-in rate limiting to"
echo "  protect backend resources and ensure fair usage across consumers."
echo ""
echo -e "${YELLOW}Technical Actions:${NC}"
echo "  • Creating API product with version metadata"
echo "  • Attaching OpenAPI specification to the catalog"
echo "  • Configuring rate limiting plugin (5 requests/minute)"
echo ""
echo -e "${BOLD}Command:${NC} gh workflow run stage4-api-product.yml"
echo ""
read -p "Press Enter to continue..."

gh workflow run stage4-api-product.yml
wait_for_workflow "stage4-api-product.yml" || exit 1

echo ""
echo -e "${GREEN}${BOLD}✓ API Product Published to Catalog${NC}"
echo -e "  Rate limiting enabled, ready for external consumption"
echo ""

# Stage 5: Developer Portal
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Stage 5: Developer Portal Publication${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Business Context:${NC}"
echo "  Making the FHIR Patient API discoverable to third-party developers through a"
echo "  self-service portal. External partners can browse documentation, test endpoints,"
echo "  register applications, and obtain API credentials without manual intervention,"
echo "  accelerating partner onboarding and reducing support overhead."
echo ""
echo -e "${YELLOW}Technical Actions:${NC}"
echo "  • Publishing API to Kong Developer Portal (v3)"
echo "  • Enabling public visibility for external access"
echo "  • Configuring application registration workflow"
echo ""
echo -e "${BOLD}Command:${NC} gh workflow run stage5-developer-portal.yml"
echo ""
read -p "Press Enter to continue..."

gh workflow run stage5-developer-portal.yml
wait_for_workflow "stage5-developer-portal.yml" || exit 1

echo ""
echo -e "${GREEN}${BOLD}✓ API Published to Developer Portal${NC}"
echo -e "  Third-party developers can now discover and consume the API"
echo ""

# Final summary
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Demo Complete! 🎉${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}What was accomplished:${NC}"
echo "  ✓ Kong Gateway control plane provisioned"
echo "  ✓ FHIR Patient API integrated with gateway"
echo "  ✓ API specification validated and tested"
echo "  ✓ API product published to catalog with rate limiting"
echo "  ✓ Developer portal configured for third-party access"
echo ""
echo -e "${YELLOW}Business Outcomes:${NC}"
echo "  • Reduced time-to-market for API partners (self-service onboarding)"
echo "  • Protected backend resources with rate limiting policies"
echo "  • Ensured API quality with automated contract testing"
echo "  • Centralized API governance and analytics"
echo "  • Compliance-ready infrastructure for healthcare data"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  • View the developer portal: https://d89b009b6d6e.au.kongportals.com"
echo "  • Monitor API analytics in Kong Konnect"
echo "  • Run './stop-demo.sh' to teardown all resources"
echo ""
