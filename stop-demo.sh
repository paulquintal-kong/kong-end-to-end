#!/bin/bash
# ========================================================================
# Kong End-to-End Demo Shutdown Script
# ========================================================================
# Stops all demo-related services:
# - Docker containers (FHIR server)
# - ngrok tunnels
# - Cleans up temporary files
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${RED}==========================================${NC}"
echo -e "${RED}Kong Demo Shutdown${NC}"
echo -e "${RED}==========================================${NC}"
echo ""

echo -e "${YELLOW}This will stop:${NC}"
echo "  • Local Kong data plane container"
echo "  • ngrok tunnels"
echo "  • Docker containers"
echo "  • Cloud resources (via destroy workflow)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

STOPPED_SERVICES=0

# ========================================================================
# 0. Stop Kong Data Plane
# ========================================================================
echo -e "${BLUE}0. Stopping Kong Data Plane...${NC}"

if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
    if docker ps -a | grep -q kong-dataplane; then
        docker-compose down kong-gateway > /dev/null 2>&1 || docker stop kong-dataplane > /dev/null 2>&1
        echo -e "${GREEN}✓${NC} Stopped Kong data plane"
        ((STOPPED_SERVICES++))
    else
        echo -e "${YELLOW}⚠${NC} Kong data plane not running"
    fi
else
    echo -e "${YELLOW}⚠${NC} Docker not available"
fi

# ========================================================================
# 1. Stop ngrok tunnels
# ========================================================================
echo -e "${BLUE}1. Checking for ngrok tunnels...${NC}"

# Check for ngrok PID file
if [ -f ".ngrok.pid" ]; then
    NGROK_PID=$(cat .ngrok.pid)
    if kill -0 "$NGROK_PID" 2>/dev/null; then
        kill "$NGROK_PID" 2>/dev/null
        echo -e "${GREEN}✓${NC} Stopped ngrok tunnel (PID: $NGROK_PID)"
        ((STOPPED_SERVICES++))
    else
        echo -e "${YELLOW}⚠${NC} Ngrok PID file exists but process not found"
    fi
    rm -f .ngrok.pid
    echo -e "${GREEN}✓${NC} Cleaned up ngrok PID file"
else
    # Try to find and kill any running ngrok processes
    if pgrep -x ngrok > /dev/null; then
        pkill -x ngrok
        echo -e "${GREEN}✓${NC} Stopped ngrok processes"
        ((STOPPED_SERVICES++))
    else
        echo -e "${CYAN}ℹ${NC} No ngrok tunnels running"
    fi
fi

# Clean up ngrok files
if [ -f ".ngrok.log" ]; then
    rm -f .ngrok.log
    echo -e "${GREEN}✓${NC} Cleaned up ngrok log file"
fi

if [ -f ".ngrok-url.txt" ]; then
    rm -f .ngrok-url.txt
    echo -e "${GREEN}✓${NC} Cleaned up ngrok URL file"
fi

echo ""

# ========================================================================
# 2. Stop Docker containers
# ========================================================================
echo -e "${BLUE}2. Checking for Docker containers...${NC}"

if [ -f "docker-compose.yml" ]; then
    # Check if any containers are running
    if docker-compose ps -q 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}Stopping Docker containers...${NC}"
        docker-compose down
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Docker containers stopped"
            ((STOPPED_SERVICES++))
        else
            echo -e "${RED}✗${NC} Failed to stop Docker containers"
            exit 1
        fi
    else
        echo -e "${CYAN}ℹ${NC} No Docker containers running"
    fi
else
    echo -e "${YELLOW}⚠${NC} docker-compose.yml not found"
fi

echo ""

# ========================================================================
# 3. Destroy Cloud Resources
# ========================================================================
echo -e "${BLUE}3. Destroying cloud resources...${NC}"

if command -v gh &> /dev/null; then
    echo -e "${YELLOW}Triggering destroy workflow...${NC}"
    gh workflow run destroy-all-stages.yml -f confirm=destroy
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Destroy workflow triggered"
        echo -e "${CYAN}Monitor: gh run list --workflow=destroy-all-stages.yml${NC}"
        ((STOPPED_SERVICES++))
    else
        echo -e "${RED}✗${NC} Failed to trigger destroy workflow"
    fi
else
    echo -e "${YELLOW}⚠${NC} GitHub CLI not available - skipping cloud resource destroy"
    echo -e "${CYAN}Manually run: gh workflow run destroy-all-stages.yml -f confirm=destroy${NC}"
fi

echo ""

# ========================================================================
# 4. Clean up local certificates and overrides
# ========================================================================
echo -e "${BLUE}4. Cleaning up local files...${NC}"

if [ -d ".kong" ]; then
    rm -rf .kong
    echo -e "${GREEN}✓${NC} Removed .kong certificates directory"
fi

if [ -f "docker-compose.override.yml" ]; then
    rm -f docker-compose.override.yml
    echo -e "${GREEN}✓${NC} Removed docker-compose.override.yml"
fi

echo ""

# ========================================================================
# 4. Remove Kong Control Plane and Configurations (optional)
# ========================================================================
echo -e "${BLUE}4. Kong Konnect Cleanup...${NC}"

read -p "Remove Kong control plane and all configurations? (y/n): " cleanup_kong
if [[ "$cleanup_kong" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}This will destroy all Kong resources created by Terraform:${NC}"
    echo -e "  - Control Plane"
    echo -e "  - Gateway Services"
    echo -e "  - Routes"
    echo -e "  - Plugins"
    echo -e "  - API Products"
    echo -e "  - Developer Portal"
    echo ""
    read -p "Are you sure? (yes/no): " confirm_destroy
    
    if [ "$confirm_destroy" = "yes" ]; then
        # Check if KONNECT_TOKEN is set
        if [ -z "$KONNECT_TOKEN" ]; then
            echo -e "${RED}✗${NC} KONNECT_TOKEN not set"
            echo -e "   ${YELLOW}Set with:${NC} export KONNECT_TOKEN='your-token'"
            exit 1
        fi
        
        # Load backend type from config file
        BACKEND_TYPE=""
        if [ -f ".demo-config" ]; then
            source .demo-config
            echo -e "${CYAN}Using backend: $BACKEND_TYPE (from .demo-config)${NC}"
        fi
        
        # Check for required backend credentials
        if [ "$BACKEND_TYPE" = "azure" ] && [ -z "$ARM_ACCESS_KEY" ]; then
            echo -e "${RED}✗${NC} ARM_ACCESS_KEY not set (required for Azure backend)"
            echo -e "   ${YELLOW}Set with:${NC} export ARM_ACCESS_KEY='your-access-key'"
            exit 1
        elif [ "$BACKEND_TYPE" = "aws" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
            echo -e "${RED}✗${NC} AWS credentials not set (required for AWS backend)"
            echo -e "   ${YELLOW}Set with:${NC} export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
            exit 1
        fi
        
        echo -e "${CYAN}Destroying Kong resources...${NC}"
        echo ""
            
            # Destroy in reverse order (5 -> 4 -> 2 -> 1)
            STAGES=("5-developer-portal" "4-api-product" "2-integration" "1-platform")
            
            for STAGE in "${STAGES[@]}"; do
                STAGE_PATH="terraform/stages/$STAGE"
                
                if [ -d "$STAGE_PATH" ]; then
                    echo -e "${CYAN}Processing stage: $STAGE${NC}"
                    cd "$STAGE_PATH"
                    
                    # Check if terraform state exists
                    if [ -d ".terraform" ] || [ -f "terraform.tfstate" ]; then
                        # Load backend type from config file
                        BACKEND_TYPE=""
                        if [ -f "../../.demo-config" ]; then
                            source ../../.demo-config
                            echo -e "${CYAN}Using backend: $BACKEND_TYPE (from .demo-config)${NC}"
                        fi
                        
                        if [ -z "$BACKEND_TYPE" ]; then
                            # Fallback to asking if config doesn't exist
                            echo -e "${YELLOW}Select backend for $STAGE:${NC}"
                            echo "   1) AWS S3"
                            echo "   2) Azure Storage"
                            echo "   3) Skip this stage"
                            read -p "Choose (1/2/3): " backend_choice
                            
                            case $backend_choice in
                                1) BACKEND_TYPE="aws" ;;
                                2) BACKEND_TYPE="azure" ;;
                                3)
                                    echo -e "${YELLOW}⊘${NC} Skipped $STAGE"
                                    cd - > /dev/null
                                    continue
                                    ;;
                                *)
                                        echo -e "${RED}✗${NC} Invalid choice, skipping"
                                    cd - > /dev/null
                                    continue
                                    ;;
                            esac
                        fi
                        
                        # Set backend config based on type
                        case $BACKEND_TYPE in
                            aws)
                                BACKEND_CONFIG="backend-aws.tfbackend"
                                ;;
                            azure)
                                BACKEND_CONFIG="backend-azure.tfbackend"
                                ;;
                            *)
                                echo -e "${RED}✗${NC} Unknown backend type: $BACKEND_TYPE"
                                cd - > /dev/null
                                continue
                                ;;
                        esac
                        
                        echo -e "${CYAN}  - Initializing terraform...${NC}"
                        INIT_OUTPUT=$(terraform init -backend-config="$BACKEND_CONFIG" -reconfigure 2>&1)
                        if [ $? -ne 0 ]; then
                            echo -e "${RED}✗${NC} Failed to initialize $STAGE"
                            echo "$INIT_OUTPUT" | grep -E "(Error:|Warning:)" | head -5
                            cd - > /dev/null
                            continue
                        fi
                        
                        # Run terraform destroy
                        echo -e "${CYAN}  - Running terraform destroy...${NC}"
                        
                        # Create tfvars file with dummy values for destroy
                        case $STAGE in
                            "5-developer-portal")
                                cat > terraform.tfvars <<EOF
konnect_token = "$KONNECT_TOKEN"
catalog_api_id = "dummy"
EOF
                                ;;
                            "4-api-product")
                                cat > terraform.tfvars <<EOF
konnect_token = "$KONNECT_TOKEN"
control_plane_id = "dummy"
service_id = "dummy"
EOF
                                ;;
                            "2-integration")
                                cat > terraform.tfvars <<EOF
konnect_token = "$KONNECT_TOKEN"
control_plane_id = "dummy"
upstream_url = "http://dummy"
EOF
                                ;;
                            "1-platform")
                                cat > terraform.tfvars <<EOF
konnect_token = "$KONNECT_TOKEN"
EOF
                                ;;
                        esac
                        
                        DESTROY_OUTPUT=$(terraform destroy -auto-approve 2>&1)
                        
                        # Check if state is locked and try to unlock
                        if echo "$DESTROY_OUTPUT" | grep -q "state blob is already locked"; then
                            echo -e "${YELLOW}⚠${NC} State is locked, attempting to unlock..."
                            LOCK_ID=$(echo "$DESTROY_OUTPUT" | grep "ID:" | head -1 | awk '{print $2}')
                            if [ ! -z "$LOCK_ID" ]; then
                                terraform force-unlock -force "$LOCK_ID" > /dev/null 2>&1
                                echo -e "${CYAN}  - Retrying destroy after unlock...${NC}"
                                DESTROY_OUTPUT=$(terraform destroy -auto-approve 2>&1)
                            fi
                        fi
                        
                        if echo "$DESTROY_OUTPUT" | grep -qE "(Destroy complete|No changes|Your infrastructure matches)"; then
                            echo -e "${GREEN}✓${NC} Destroyed $STAGE resources"
                            
                            # Clean up local terraform files
                            rm -rf .terraform
                            rm -f terraform.tfstate*
                            rm -f .terraform.lock.hcl
                            echo -e "${GREEN}✓${NC} Cleaned up $STAGE terraform files"
                        else
                            echo -e "${YELLOW}⚠${NC} Failed to destroy $STAGE"
                            echo "$DESTROY_OUTPUT" | grep -E "(Error:|Warning:)" | head -5
                        fi
                    else
                        echo -e "${CYAN}ℹ${NC} $STAGE - No terraform state found"
                    fi
                    
                    cd - > /dev/null
                    echo ""
                fi
            done
            
            # Clean up output files
            rm -f terraform/stages/stage*.json
            echo -e "${GREEN}✓${NC} Cleaned up stage output files"
            
            ((STOPPED_SERVICES++))
        fi
        echo -e "${CYAN}ℹ${NC} Kong cleanup cancelled"
    fi
else
    echo -e "${CYAN}ℹ${NC} Skipping Kong cleanup"
fi

echo ""

# ========================================================================
# Summary
# ========================================================================
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Shutdown Complete${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

if [ $STOPPED_SERVICES -gt 0 ]; then
    echo -e "${GREEN}Stopped $STOPPED_SERVICES service(s)${NC}"
else
    echo -e "${CYAN}No services were running${NC}"
fi

echo ""
echo -e "${CYAN}To start the demo again:${NC}"
echo -e "  1. Run: ${YELLOW}./init-demo.sh${NC} (to verify environment)"
echo -e "  2. Start with Stage 1: ${YELLOW}cd terraform/stages/1-platform && ./demo.sh${NC}"
echo ""

exit 0
