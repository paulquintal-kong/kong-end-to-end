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

STOPPED_SERVICES=0

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
# 3. Clean up Terraform lock files (optional)
# ========================================================================
echo -e "${BLUE}3. Cleaning up temporary files...${NC}"

# Remove Terraform lock files if user wants
read -p "Remove Terraform lock files? (y/n): " cleanup_tf
if [[ "$cleanup_tf" =~ ^[Yy]$ ]]; then
    find terraform/stages -name ".terraform.lock.hcl" -delete 2>/dev/null && \
        echo -e "${GREEN}✓${NC} Removed Terraform lock files" || \
        echo -e "${CYAN}ℹ${NC} No Terraform lock files found"
fi

# Remove tfvars files
read -p "Remove terraform.tfvars files? (y/n): " cleanup_tfvars
if [[ "$cleanup_tfvars" =~ ^[Yy]$ ]]; then
    find terraform/stages -name "terraform.tfvars" -delete 2>/dev/null && \
        echo -e "${GREEN}✓${NC} Removed terraform.tfvars files" || \
        echo -e "${CYAN}ℹ${NC} No tfvars files found"
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
        else
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
                        # Select backend
                        echo -e "${YELLOW}Select backend for $STAGE:${NC}"
                        echo "   1) AWS S3"
                        echo "   2) Azure Storage"
                        echo "   3) Skip this stage"
                        read -p "Choose (1/2/3): " backend_choice
                        
                        case $backend_choice in
                            1)
                                BACKEND_CONFIG="backend-aws.tfbackend"
                                terraform init -backend-config="$BACKEND_CONFIG" -reconfigure > /dev/null 2>&1
                                ;;
                            2)
                                BACKEND_CONFIG="backend-azure.tfbackend"
                                terraform init -backend-config="$BACKEND_CONFIG" -reconfigure > /dev/null 2>&1
                                ;;
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
                        
                        # Run terraform destroy
                        if terraform destroy -auto-approve > /dev/null 2>&1; then
                            echo -e "${GREEN}✓${NC} Destroyed $STAGE resources"
                            
                            # Clean up local terraform files
                            rm -rf .terraform
                            rm -f terraform.tfstate*
                            rm -f .terraform.lock.hcl
                            echo -e "${GREEN}✓${NC} Cleaned up $STAGE terraform files"
                        else
                            echo -e "${YELLOW}⚠${NC} Failed to destroy $STAGE (may not exist or already destroyed)"
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
    else
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
