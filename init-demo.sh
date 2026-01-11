#!/bin/bash
# ========================================================================
# Kong End-to-End Demo Initialization Script
# ========================================================================
# This script validates and sets up the environment for running the demo
# - Checks required CLI tools
# - Validates environment variables
# - Verifies cloud backend configuration (AWS or Azure)
# - Tests backend connectivity
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

echo ""
echo "=========================================="
echo "Kong End-to-End Demo Initialization"
echo "=========================================="
echo ""

# ========================================================================
# Execution Method Selection
# ========================================================================
echo -e "${BLUE}How would you like to run the demo?${NC}"
echo -e "  1) ${CYAN}GitHub Workflow${NC} (Recommended - automated via CI/CD)"
echo -e "  2) ${YELLOW}Local Command Line${NC} (Manual execution)"
echo ""
read -p "Choose execution method (1 or 2) [1]: " exec_method
exec_method=${exec_method:-1}

EXECUTION_MODE="workflow"
if [ "$exec_method" = "2" ]; then
    EXECUTION_MODE="local"
    echo -e "${GREEN}✓${NC} Selected: Local command line execution"
else
    EXECUTION_MODE="workflow"
    echo -e "${GREEN}✓${NC} Selected: GitHub Workflow (automated)"
fi

echo ""

# ========================================================================
# Function: Check if a command exists
# ========================================================================
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    local required=$4  # true or false
    
    if command -v "$cmd" &> /dev/null; then
        VERSION=$($cmd --version 2>&1 | head -n 1 || echo "installed")
        echo -e "${GREEN}✓${NC} $name: ${CYAN}$VERSION${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} $name: Not found"
            echo -e "   ${YELLOW}Install:${NC} $install_hint"
            
            # Offer auto-install for brew packages
            if [[ "$install_hint" == brew* ]] && command -v brew &> /dev/null; then
                read -p "   Would you like to install $name now? (y/n): " install_choice
                if [[ "$install_choice" =~ ^[Yy]$ ]]; then
                    echo -e "   ${CYAN}Installing $name...${NC}"
                    eval "$install_hint"
                    if [ $? -eq 0 ]; then
                        VERSION=$($cmd --version 2>&1 | head -n 1 || echo "installed")
                        echo -e "   ${GREEN}✓ $name installed successfully: $VERSION${NC}"
                        ((CHECKS_PASSED++))
                        return 0
                    else
                        echo -e "   ${RED}✗ Failed to install $name${NC}"
                        ((CHECKS_FAILED++))
                        return 1
                    fi
                fi
            fi
            
            ((CHECKS_FAILED++))
            return 1
        else
            echo -e "${YELLOW}⚠${NC} $name: Not found (optional)"
            echo -e "   ${YELLOW}Install:${NC} $install_hint"
            ((WARNINGS++))
            return 0
        fi
    fi
}

# ========================================================================
# 1. Check Required CLI Tools
# ========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. Checking Required CLI Tools${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Terraform (required)
check_command "terraform" "Terraform" "brew install terraform" "true"

# jq (required for parsing JSON)
check_command "jq" "jq (JSON processor)" "brew install jq" "true"

# curl (required)
check_command "curl" "curl" "brew install curl" "true"

# Docker (required for local FHIR server)
check_command "docker" "Docker" "https://docs.docker.com/get-docker/" "true"

echo ""

# ========================================================================
# 2. Check Optional CLI Tools
# ========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. Checking Optional CLI Tools${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

OPTIONAL_TOOLS_MISSING=()

# GitHub CLI (optional)
if ! check_command "gh" "GitHub CLI" "brew install gh" "false"; then
    OPTIONAL_TOOLS_MISSING+=("gh:brew install gh")
fi

# AWS CLI (optional, needed if using AWS backend)
if ! check_command "aws" "AWS CLI" "brew install awscli" "false"; then
    OPTIONAL_TOOLS_MISSING+=("aws:brew install awscli")
fi

# Azure CLI (optional, needed if using Azure backend)
if ! check_command "az" "Azure CLI" "brew install azure-cli" "false"; then
    OPTIONAL_TOOLS_MISSING+=("az:brew install azure-cli")
fi

# ngrok (optional, for local FHIR server tunneling)
if ! check_command "ngrok" "ngrok" "brew install ngrok/ngrok/ngrok" "false"; then
    OPTIONAL_TOOLS_MISSING+=("ngrok:brew install ngrok/ngrok/ngrok")
fi

# Offer batch install of optional tools
if [ ${#OPTIONAL_TOOLS_MISSING[@]} -gt 0 ] && command -v brew &> /dev/null; then
    echo ""
    read -p "   Would you like to install missing optional tools? (y/n): " install_optional
    if [[ "$install_optional" =~ ^[Yy]$ ]]; then
        for tool_info in "${OPTIONAL_TOOLS_MISSING[@]}"; do
            tool_name="${tool_info%%:*}"
            install_cmd="${tool_info#*:}"
            echo -e "   ${CYAN}Installing $tool_name...${NC}"
            eval "$install_cmd" &> /dev/null
            if [ $? -eq 0 ]; then
                echo -e "   ${GREEN}✓${NC} $tool_name installed"
                # Decrement warnings since it's now installed
                ((WARNINGS--))
            else
                echo -e "   ${YELLOW}⚠${NC} Failed to install $tool_name"
            fi
        done
    fi
fi

echo ""

# ========================================================================
# 3. Check Environment Variables
# ========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. Checking Environment Variables${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# KONNECT_TOKEN (required)
if [ -z "$KONNECT_TOKEN" ]; then
    echo -e "${RED}✗${NC} KONNECT_TOKEN: Not set"
    echo -e "   ${YELLOW}Get token:${NC} https://cloud.konghq.com/global/account/tokens"
    echo ""
    read -p "   Would you like to set KONNECT_TOKEN now? (y/n): " set_token
    if [[ "$set_token" =~ ^[Yy]$ ]]; then
        read -p "   Enter your Kong Konnect token: " user_token
        if [ ! -z "$user_token" ]; then
            export KONNECT_TOKEN="$user_token"
            TOKEN_PREVIEW="${KONNECT_TOKEN:0:20}..."
            echo -e "   ${GREEN}✓${NC} KONNECT_TOKEN set: ${CYAN}$TOKEN_PREVIEW${NC}"
            echo -e "   ${YELLOW}Note:${NC} Add to your shell profile to persist:"
            echo -e "   ${YELLOW}echo 'export KONNECT_TOKEN=\"$user_token\"' >> ~/.zshrc${NC}"
            ((CHECKS_PASSED++))
        else
            echo -e "   ${RED}✗${NC} No token provided"
            ((CHECKS_FAILED++))
        fi
    else
        echo -e "   ${YELLOW}Set with:${NC} export KONNECT_TOKEN='your-token'"
        ((CHECKS_FAILED++))
    fi
else
    TOKEN_PREVIEW="${KONNECT_TOKEN:0:20}..."
    echo -e "${GREEN}✓${NC} KONNECT_TOKEN: ${CYAN}$TOKEN_PREVIEW${NC}"
    ((CHECKS_PASSED++))
fi

echo ""

# ========================================================================
# 4. Detect and Validate Cloud Backend
# ========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. Cloud Backend Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

BACKEND_SELECTED="none"

# Check for AWS credentials
if [ ! -z "$AWS_ACCESS_KEY_ID" ] || [ -f ~/.aws/credentials ]; then
    echo -e "${CYAN}AWS Backend Detected${NC}"
    
    if [ ! -z "$AWS_ACCESS_KEY_ID" ] && [ ! -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo -e "${GREEN}✓${NC} AWS Credentials: Environment variables set"
        ((CHECKS_PASSED++))
        BACKEND_SELECTED="aws"
        
        # Test AWS CLI if available
        if command -v aws &> /dev/null; then
            AWS_REGION="${AWS_DEFAULT_REGION:-ap-southeast-2}"
            echo -e "${CYAN}  Testing AWS connection...${NC}"
            
            if aws sts get-caller-identity --region "$AWS_REGION" &> /dev/null; then
                CALLER_ID=$(aws sts get-caller-identity --region "$AWS_REGION" --query 'Arn' --output text 2>/dev/null || echo "authenticated")
                echo -e "${GREEN}✓${NC} AWS Connection: ${CYAN}$CALLER_ID${NC}"
                
                # Check if S3 bucket exists
                BUCKET_NAME="kong-fhir-tfstate"
                echo -e "${CYAN}  Checking S3 bucket: $BUCKET_NAME...${NC}"
                if aws s3 ls "s3://$BUCKET_NAME" --region "$AWS_REGION" &> /dev/null; then
                    echo -e "${GREEN}✓${NC} S3 Bucket: ${CYAN}$BUCKET_NAME exists${NC}"
                    ((CHECKS_PASSED++))
                else
                    echo -e "${YELLOW}⚠${NC} S3 Bucket: $BUCKET_NAME not found"
                    echo ""
                    read -p "   Would you like to create the S3 bucket now? (y/n): " create_bucket
                    if [[ "$create_bucket" =~ ^[Yy]$ ]]; then
                        echo -e "   ${CYAN}Creating S3 bucket: $BUCKET_NAME...${NC}"
                        if aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"; then
                            echo -e "   ${GREEN}✓${NC} S3 bucket created"
                            
                            # Enable versioning
                            echo -e "   ${CYAN}Enabling versioning...${NC}"
                            if aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled --region "$AWS_REGION"; then
                                echo -e "   ${GREEN}✓${NC} Versioning enabled"
                                ((CHECKS_PASSED++))
                            else
                                echo -e "   ${YELLOW}⚠${NC} Failed to enable versioning"
                                ((WARNINGS++))
                            fi
                        else
                            echo -e "   ${RED}✗${NC} Failed to create S3 bucket"
                            ((WARNINGS++))
                        fi
                    else
                        echo -e "   ${YELLOW}Create manually:${NC} aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION"
                        echo -e "   ${YELLOW}Enable versioning:${NC} aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled"
                        ((WARNINGS++))
                    fi
                fi
            else
                echo -e "${RED}✗${NC} AWS Connection: Failed to authenticate"
                echo -e "   ${YELLOW}Check credentials and permissions${NC}"
                ((CHECKS_FAILED++))
            fi
        fi
    elif [ -f ~/.aws/credentials ]; then
        echo -e "${GREEN}✓${NC} AWS Credentials: ${CYAN}~/.aws/credentials file found${NC}"
        echo -e "   ${YELLOW}Note:${NC} Environment variables not set. AWS CLI will use credentials file."
        ((CHECKS_PASSED++))
        BACKEND_SELECTED="aws"
    else
        echo -e "${YELLOW}⚠${NC} AWS Credentials: Detected but incomplete"
        echo -e "   ${YELLOW}Set with:${NC} export AWS_ACCESS_KEY_ID='your-key'"
        echo -e "   ${YELLOW}         ${NC} export AWS_SECRET_ACCESS_KEY='your-secret'"
        ((WARNINGS++))
    fi
    
    echo ""
fi

# Check for Azure credentials
if [ ! -z "$ARM_ACCESS_KEY" ] || command -v az &> /dev/null; then
    echo -e "${CYAN}Azure Backend Detected${NC}"
    
    if [ ! -z "$ARM_ACCESS_KEY" ]; then
        echo -e "${GREEN}✓${NC} Azure Credentials: ARM_ACCESS_KEY set"
        ((CHECKS_PASSED++))
        BACKEND_SELECTED="azure"
        
        # Test Azure storage if account name is known
        STORAGE_ACCOUNT="kongfhirtfstate"
        RESOURCE_GROUP="kong-terraform-state"
        echo -e "${CYAN}  Testing Azure Storage access...${NC}"
        
        if command -v az &> /dev/null; then
            if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
                echo -e "${GREEN}✓${NC} Azure Storage: ${CYAN}$STORAGE_ACCOUNT exists${NC}"
                ((CHECKS_PASSED++))
            else
                echo -e "${YELLOW}⚠${NC} Azure Storage: $STORAGE_ACCOUNT not found"
                echo -e "   ${YELLOW}Create with:${NC} az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT --sku Standard_LRS"
                ((WARNINGS++))
            fi
        fi
    elif command -v az &> /dev/null; then
        # Check if logged in via Azure CLI
        if az account show &> /dev/null; then
            AZURE_ACCOUNT=$(az account show --query 'name' -o tsv 2>/dev/null || echo "authenticated")
            echo -e "${GREEN}✓${NC} Azure CLI: Logged in as ${CYAN}$AZURE_ACCOUNT${NC}"
            ((CHECKS_PASSED++))
            BACKEND_SELECTED="azure"
            
            # Check storage account
            STORAGE_ACCOUNT="kongfhirtfstate"
            RESOURCE_GROUP="kong-terraform-state"
            echo -e "${CYAN}  Checking Azure Storage: $STORAGE_ACCOUNT...${NC}"
            
            if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
                echo -e "${GREEN}✓${NC} Azure Storage: ${CYAN}$STORAGE_ACCOUNT exists${NC}"
                
                # Get access key
                echo -e "${CYAN}  Getting storage account key...${NC}"
                ACCOUNT_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query '[0].value' -o tsv 2>/dev/null)
                if [ ! -z "$ACCOUNT_KEY" ]; then
                    echo -e "${GREEN}✓${NC} Storage Key: Retrieved successfully"
                    if [ -z "$ARM_ACCESS_KEY" ]; then
                        echo ""
                        read -p "   Would you like to set ARM_ACCESS_KEY now? (y/n): " set_key
                        if [[ "$set_key" =~ ^[Yy]$ ]]; then
                            export ARM_ACCESS_KEY="$ACCOUNT_KEY"
                            echo -e "   ${GREEN}✓${NC} ARM_ACCESS_KEY set"
                            echo -e "   ${YELLOW}Note:${NC} Add to your shell profile to persist:"
                            echo -e "   ${YELLOW}echo 'export ARM_ACCESS_KEY=\"***\"' >> ~/.zshrc${NC}"
                        else
                            echo -e "   ${YELLOW}Tip:${NC} export ARM_ACCESS_KEY='$ACCOUNT_KEY'"
                        fi
                    fi
                fi
            else
                echo -e "${YELLOW}⚠${NC} Azure Storage: $STORAGE_ACCOUNT not found"
                echo ""
                read -p "   Would you like to create Azure Storage resources now? (y/n): " create_storage
                if [[ "$create_storage" =~ ^[Yy]$ ]]; then
                    echo -e "   ${CYAN}Creating resource group: $RESOURCE_GROUP...${NC}"
                    if az group create --name "$RESOURCE_GROUP" --location australiaeast &> /dev/null; then
                        echo -e "   ${GREEN}✓${NC} Resource group created"
                        
                        echo -e "   ${CYAN}Creating storage account: $STORAGE_ACCOUNT...${NC}"
                        if az storage account create --resource-group "$RESOURCE_GROUP" --name "$STORAGE_ACCOUNT" --sku Standard_LRS --encryption-services blob &> /dev/null; then
                            echo -e "   ${GREEN}✓${NC} Storage account created"
                            
                            echo -e "   ${CYAN}Creating container: tfstate...${NC}"
                            if az storage container create --name tfstate --account-name "$STORAGE_ACCOUNT" &> /dev/null; then
                                echo -e "   ${GREEN}✓${NC} Container created"
                                
                                # Get and set access key
                                ACCOUNT_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query '[0].value' -o tsv 2>/dev/null)
                                export ARM_ACCESS_KEY="$ACCOUNT_KEY"
                                echo -e "   ${GREEN}✓${NC} ARM_ACCESS_KEY set automatically"
                                echo -e "   ${YELLOW}Note:${NC} Add to your shell profile to persist"
                                ((CHECKS_PASSED++))
                            else
                                echo -e "   ${RED}✗${NC} Failed to create container"
                                ((WARNINGS++))
                            fi
                        else
                            echo -e "   ${RED}✗${NC} Failed to create storage account"
                            ((WARNINGS++))
                        fi
                    else
                        echo -e "   ${RED}✗${NC} Failed to create resource group"
                        ((WARNINGS++))
                    fi
                else
                    echo -e "   ${YELLOW}Create manually:${NC}"
                    echo -e "   ${YELLOW}  az group create --name $RESOURCE_GROUP --location australiaeast${NC}"
                    echo -e "   ${YELLOW}  az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT --sku Standard_LRS${NC}"
                    echo -e "   ${YELLOW}  az storage container create --name tfstate --account-name $STORAGE_ACCOUNT${NC}"
                    ((WARNINGS++))
                fi
            fi
        else
            echo -e "${YELLOW}⚠${NC} Azure CLI: Not logged in"
            echo -e "   ${YELLOW}Login with:${NC} az login"
            ((WARNINGS++))
        fi
    fi
    
    echo ""
fi

# Backend summary
if [ "$BACKEND_SELECTED" = "none" ]; then
    echo -e "${RED}✗${NC} No cloud backend configured"
    echo ""
    read -p "   Would you like to configure a cloud backend now? (aws/azure/skip): " backend_choice
    
    case "$backend_choice" in
        aws|AWS)
            echo -e "   ${CYAN}Configuring AWS backend...${NC}"
            echo ""
            read -p "   Enter AWS Access Key ID: " aws_key
            read -p "   Enter AWS Secret Access Key: " aws_secret
            read -p "   Enter AWS Region [ap-southeast-2]: " aws_region
            aws_region=${aws_region:-ap-southeast-2}
            
            if [ ! -z "$aws_key" ] && [ ! -z "$aws_secret" ]; then
                export AWS_ACCESS_KEY_ID="$aws_key"
                export AWS_SECRET_ACCESS_KEY="$aws_secret"
                export AWS_DEFAULT_REGION="$aws_region"
                echo -e "   ${GREEN}✓${NC} AWS credentials set"
                echo -e "   ${YELLOW}Note:${NC} Add to your shell profile to persist:"
                echo -e "   ${YELLOW}echo 'export AWS_ACCESS_KEY_ID=\"$aws_key\"' >> ~/.zshrc${NC}"
                echo -e "   ${YELLOW}echo 'export AWS_SECRET_ACCESS_KEY=\"$aws_secret\"' >> ~/.zshrc${NC}"
                BACKEND_SELECTED="aws"
                
                # Save backend selection to config file
                echo "BACKEND_TYPE=aws" > .demo-config
                echo -e "   ${GREEN}✓${NC} Backend configuration saved to .demo-config"
                
                # Offer to create S3 bucket
                if command -v aws &> /dev/null; then
                    echo ""
                    read -p "   Create S3 bucket for Terraform state? (y/n): " create_s3
                    if [[ "$create_s3" =~ ^[Yy]$ ]]; then
                        BUCKET_NAME="kong-fhir-tfstate"
                        echo -e "   ${CYAN}Creating S3 bucket: $BUCKET_NAME...${NC}"
                        if aws s3 mb "s3://$BUCKET_NAME" --region "$aws_region" 2>/dev/null; then
                            echo -e "   ${GREEN}✓${NC} S3 bucket created"
                            aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled --region "$aws_region" 2>/dev/null
                            echo -e "   ${GREEN}✓${NC} Versioning enabled"
                        fi
                    fi
                fi
            fi
            ;;
        azure|AZURE|Azure)
            echo -e "   ${CYAN}Configuring Azure backend...${NC}"
            if command -v az &> /dev/null; then
                echo -e "   ${CYAN}Logging into Azure...${NC}"
                az login
                if [ $? -eq 0 ]; then
                    echo -e "   ${GREEN}✓${NC} Azure login successful"
                    BACKEND_SELECTED="azure"
                    
                    # Save backend selection to config file
                    echo "BACKEND_TYPE=azure" > .demo-config
                    echo -e "   ${GREEN}✓${NC} Backend configuration saved to .demo-config"
                    
                    # Offer to create storage resources
                    echo ""
                    read -p "   Create Azure Storage for Terraform state? (y/n): " create_azure
                    if [[ "$create_azure" =~ ^[Yy]$ ]]; then
                        RESOURCE_GROUP="kong-terraform-state"
                        STORAGE_ACCOUNT="kongfhirtfstate"
                        
                        echo -e "   ${CYAN}Creating resource group...${NC}"
                        az group create --name "$RESOURCE_GROUP" --location australiaeast &> /dev/null
                        echo -e "   ${CYAN}Creating storage account...${NC}"
                        az storage account create --resource-group "$RESOURCE_GROUP" --name "$STORAGE_ACCOUNT" --sku Standard_LRS &> /dev/null
                        echo -e "   ${CYAN}Creating container...${NC}"
                        az storage container create --name tfstate --account-name "$STORAGE_ACCOUNT" &> /dev/null
                        
                        ACCOUNT_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query '[0].value' -o tsv 2>/dev/null)
                        export ARM_ACCESS_KEY="$ACCOUNT_KEY"
                        echo -e "   ${GREEN}✓${NC} Azure Storage configured"
                    fi
                fi
            else
                echo -e "   ${RED}✗${NC} Azure CLI not installed"
                echo -e "   ${YELLOW}Install with:${NC} brew install azure-cli"
            fi
            ;;
        *)
            echo -e "   ${YELLOW}Skipping backend configuration${NC}"
            echo -e "   ${YELLOW}Configure manually - see:${NC} terraform/BACKEND-CONFIG.md"
            ((CHECKS_FAILED++))
            ;;
    esac
    echo ""
else
    echo -e "${GREEN}✓${NC} Backend Selected: ${CYAN}$BACKEND_SELECTED${NC}"
    
    # Save backend selection to config file if not already saved
    if [ ! -f ".demo-config" ]; then
        echo "BACKEND_TYPE=$BACKEND_SELECTED" > .demo-config
        echo -e "${GREEN}✓${NC} Backend configuration saved to .demo-config"
    fi
fi

echo ""

# ========================================================================
# 5. Check Terraform Backend Files
# ========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. Terraform Backend Configuration Files${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

STAGES=("1-platform" "2-integration" "4-api-product" "5-developer-portal")

for STAGE in "${STAGES[@]}"; do
    STAGE_PATH="terraform/stages/$STAGE"
    
    if [ -f "$STAGE_PATH/backend-aws.tfbackend" ] && [ -f "$STAGE_PATH/backend-azure.tfbackend" ]; then
        echo -e "${GREEN}✓${NC} $STAGE: Backend config files present"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} $STAGE: Missing backend config files"
        echo -e "   ${YELLOW}Expected:${NC} backend-aws.tfbackend, backend-azure.tfbackend"
        ((CHECKS_FAILED++))
    fi
done

echo ""

# ========================================================================
# 6. Docker Check
# ========================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. Docker Environment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v docker &> /dev/null; then
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker: Daemon is running"
        
        # Check for docker-compose
        if [ -f "docker-compose.yml" ]; then
            echo -e "${GREEN}✓${NC} docker-compose.yml: Found"
            ((CHECKS_PASSED++))
        else
            echo -e "${YELLOW}⚠${NC} docker-compose.yml: Not found"
            echo -e "   ${YELLOW}Note:${NC} Required for local FHIR server"
            ((WARNINGS++))
        fi
    else
        echo -e "${RED}✗${NC} Docker: Daemon not running"
        echo ""
        read -p "   Would you like to start Docker now? (y/n): " start_docker
        if [[ "$start_docker" =~ ^[Yy]$ ]]; then
            echo -e "   ${CYAN}Starting Docker...${NC}"
            # Try to start Docker Desktop on macOS
            if [ "$(uname)" = "Darwin" ]; then
                open -a Docker
                echo -e "   ${CYAN}Waiting for Docker to start (up to 30 seconds)...${NC}"
                
                # Wait for Docker to be ready
                timeout=30
                counter=0
                while ! docker info &> /dev/null; do
                    sleep 2
                    counter=$((counter + 2))
                    if [ $counter -ge $timeout ]; then
                        echo -e "   ${RED}✗${NC} Docker failed to start in time"
                        echo -e "   ${YELLOW}Please start Docker Desktop manually${NC}"
                        ((CHECKS_FAILED++))
                        break
                    fi
                done
                
                if docker info &> /dev/null; then
                    echo -e "   ${GREEN}✓${NC} Docker is now running"
                    ((CHECKS_PASSED++))
                fi
            else
                echo -e "   ${YELLOW}Start Docker manually:${NC} sudo systemctl start docker"
                ((CHECKS_FAILED++))
            fi
        else
            echo -e "   ${YELLOW}Start Docker manually or with:${NC} open -a Docker (macOS)"
            ((CHECKS_FAILED++))
        fi
    fi
else
    echo -e "${RED}✗${NC} Docker: Not installed"
    ((CHECKS_FAILED++))
fi

echo ""

# ========================================================================
# Summary Report
# ========================================================================
echo ""
echo -e "${BLUE}=========================================="
echo -e "Initialization Summary"
echo -e "==========================================${NC}"
echo ""
echo -e "Checks Passed:  ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Checks Failed:  ${RED}$CHECKS_FAILED${NC}"
echo -e "Warnings:       ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Environment is ready for demo!${NC}"
    echo ""
    
    # ========================================================================
    # Start FHIR Server and ngrok (required for both local and workflow modes)
    # ========================================================================
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Starting Backend Services${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Start Docker containers (HAPI FHIR only - Kong Gateway deployed after Stage 1)
    if docker info &> /dev/null && [ -f "docker-compose.yml" ]; then
        echo -e "${CYAN}Starting HAPI FHIR server...${NC}"
        if docker-compose up -d fhir-server; then
            echo -e "${GREEN}✓${NC} HAPI FHIR server started"
            echo -e "   ${CYAN}URL:${NC} http://localhost:8080/fhir"
            echo -e "   ${YELLOW}Note:${NC} Kong Gateway will be deployed after Stage 1 (Control Plane)"
            
            # Wait for FHIR server to be ready
            echo -e "${CYAN}Waiting for FHIR server to be ready...${NC}"
            timeout=60
            counter=0
            while ! curl -s http://localhost:8080/fhir/metadata > /dev/null 2>&1; do
                sleep 2
                counter=$((counter + 2))
                if [ $counter -ge $timeout ]; then
                    echo -e "${YELLOW}⚠${NC} FHIR server taking longer than expected to start"
                    echo -e "   ${YELLOW}Continue anyway - it may still be initializing${NC}"
                    break
                fi
                echo -n "."
            done
            echo ""
            
            if curl -s http://localhost:8080/fhir/metadata > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} FHIR server is ready"
            fi
        else
            echo -e "${RED}✗${NC} Failed to start HAPI FHIR server"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Skipping Docker - daemon not running or docker-compose.yml not found"
    fi
    
    echo ""
    
    # Start ngrok tunnel
    if command -v ngrok &> /dev/null; then
        echo -e "${CYAN}Starting ngrok tunnel...${NC}"
        
        # Kill any existing ngrok processes
        pkill -x ngrok 2>/dev/null || true
        
        # Start ngrok in background
        ngrok http 8080 --log=stdout > .ngrok.log 2>&1 &
        NGROK_PID=$!
        echo $NGROK_PID > .ngrok.pid
        
        # Wait for ngrok to be ready
        sleep 3
        
        # Get ngrok URL
        if command -v jq &> /dev/null; then
            NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
        else
            NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok-free\.dev')
        fi
        
        if [ ! -z "$NGROK_URL" ]; then
            echo -e "${GREEN}✓${NC} ngrok tunnel started"
            echo -e "   ${CYAN}Public URL:${NC} $NGROK_URL"
            echo -e "   ${CYAN}FHIR Endpoint:${NC} $NGROK_URL/fhir"
            echo "$NGROK_URL" > .ngrok-url.txt
            
            # Save to demo state config
            cat > .demo-state.json <<STATE_EOF
{
  "version": "1.0",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "execution_mode": "$EXECUTION_MODE",
  "backend_type": "$BACKEND_SELECTED",
  "ngrok_url": "$NGROK_URL",
  "fhir_endpoint": "$NGROK_URL/fhir",
  "control_plane_id": null,
  "service_id": null,
  "catalog_service_id": null,
  "catalog_api_id": null,
  "portal_id": null
}
STATE_EOF
            
            echo ""
            echo -e "${GREEN}✓${NC} Demo configuration saved to .demo-state.json"
            echo -e "${YELLOW}Important:${NC} Workflows will automatically use this configuration"
        else
            echo -e "${YELLOW}⚠${NC} ngrok started but URL not available yet"
            echo -e "   ${YELLOW}Check URL with:${NC} curl http://localhost:4040/api/tunnels"
        fi
    else
        echo -e "${YELLOW}⚠${NC} ngrok not installed - skipping tunnel setup"
        echo -e "   ${YELLOW}You'll need to configure a public URL manually${NC}"
    fi
    
    echo ""
    
    if [ "$EXECUTION_MODE" = "workflow" ]; then
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}GitHub Workflow Setup${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # Check if GitHub CLI is available
        if command -v gh &> /dev/null; then
            # Check if we're in a git repo
            if git rev-parse --git-dir > /dev/null 2>&1; then
                echo -e "${BLUE}Configuring GitHub Actions workflow...${NC}"
                echo -e "${GREEN}✓${NC} Stage-specific workflows already exist"
                
                # Skip workflow generation - workflows already exist
                # Workflows: stage1-platform.yml, stage2-integration.yml, etc.
                
                : <<'WORKFLOW_EOF'
name: Kong Demo Deployment

on:
  push:
    branches:
      - main
      - master
    paths:
      - 'terraform/**'
      - '.github/workflows/kong-demo.yml'
  workflow_dispatch:
    inputs:
      destroy:
        description: 'Destroy infrastructure'
        required: false
        type: boolean
        default: false

env:
  TF_VERSION: '1.14.3'

jobs:
  deploy:
    name: Deploy Kong Infrastructure
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Configure Azure credentials
        run: |
          echo "ARM_ACCESS_KEY=${{ secrets.ARM_ACCESS_KEY }}" >> $GITHUB_ENV
      
      - name: Stage 1 - Platform
        if: ${{ !inputs.destroy }}
        working-directory: terraform/stages/1-platform
        run: |
          cat > terraform.tfvars <<EOF
          konnect_token = "${{ secrets.KONNECT_TOKEN }}"
          environment   = "production"
          project_name  = "fhir-patient-records"
          EOF
          
          terraform init -backend-config=backend-azure.tfbackend
          terraform plan
          terraform apply -auto-approve
          terraform output -json > ../stage1-outputs.json
      
      - name: Stage 2 - Integration
        if: ${{ !inputs.destroy }}
        working-directory: terraform/stages/2-integration
        run: |
          CONTROL_PLANE_ID=$(jq -r '.control_plane_id.value' ../stage1-outputs.json)
          
          cat > terraform.tfvars <<EOF
          konnect_token    = "${{ secrets.KONNECT_TOKEN }}"
          control_plane_id = "$CONTROL_PLANE_ID"
          upstream_url     = "https://asia-bosker-renna.ngrok-free.dev/fhir"
          EOF
          
          terraform init -backend-config=backend-azure.tfbackend
          terraform plan
          terraform apply -auto-approve
          terraform output -json > ../stage2-outputs.json
      
      - name: Stage 4 - API Product
        if: ${{ !inputs.destroy }}
        working-directory: terraform/stages/4-api-product
        run: |
          CONTROL_PLANE_ID=$(jq -r '.control_plane_id.value' ../stage1-outputs.json)
          SERVICE_ID=$(jq -r '.service_id.value' ../stage2-outputs.json)
          
          cat > terraform.tfvars <<EOF
          konnect_token         = "${{ secrets.KONNECT_TOKEN }}"
          control_plane_id      = "$CONTROL_PLANE_ID"
          service_id            = "$SERVICE_ID"
          rate_limit_per_minute = 5
          EOF
          
          terraform init -backend-config=backend-azure.tfbackend
          terraform plan
          terraform apply -auto-approve
          terraform output -json > ../stage3-outputs.json
      
      - name: Stage 5 - Developer Portal
        if: ${{ !inputs.destroy }}
        working-directory: terraform/stages/5-developer-portal
        run: |
          CATALOG_API_ID=$(jq -r '.catalog_api_id.value' ../stage3-outputs.json)
          
          cat > terraform.tfvars <<EOF
          konnect_token           = "${{ secrets.KONNECT_TOKEN }}"
          catalog_api_id          = "$CATALOG_API_ID"
          portal_name             = "Patient Records API"
          portal_display_name     = "Developer Portal"
          enable_auth             = false
          auto_approve_developers = false
          EOF
          
          terraform init -backend-config=backend-azure.tfbackend
          terraform plan
          terraform apply -auto-approve
      
      - name: Destroy Infrastructure
        if: ${{ inputs.destroy }}
        run: |
          echo "Destroying infrastructure in reverse order..."
          
          cd terraform/stages/5-developer-portal
          terraform init -backend-config=backend-azure.tfbackend
          terraform destroy -auto-approve -var="konnect_token=${{ secrets.KONNECT_TOKEN }}" -var="catalog_api_id=dummy" || true
          
          cd ../4-api-product
          terraform init -backend-config=backend-azure.tfbackend
          terraform destroy -auto-approve -var="konnect_token=${{ secrets.KONNECT_TOKEN }}" -var="control_plane_id=dummy" -var="service_id=dummy" || true
          
          cd ../2-integration
          terraform init -backend-config=backend-azure.tfbackend
          terraform destroy -auto-approve -var="konnect_token=${{ secrets.KONNECT_TOKEN }}" -var="control_plane_id=dummy" -var="upstream_url=dummy" || true
          
          cd ../1-platform
          terraform init -backend-config=backend-azure.tfbackend
          terraform destroy -auto-approve -var="konnect_token=${{ secrets.KONNECT_TOKEN }}" || true
WORKFLOW_EOF
                
                echo -e "${GREEN}✓${NC} GitHub Actions workflows ready (stage1-platform.yml, stage2-integration.yml, etc.)"
                
                # Set GitHub secrets
                echo ""
                echo -e "${YELLOW}Setting up GitHub secrets...${NC}"
                
                # Check if secrets exist, if not, create them
                if [ ! -z "$KONNECT_TOKEN" ]; then
                    gh secret set KONNECT_TOKEN --body "$KONNECT_TOKEN" 2>/dev/null && \
                        echo -e "${GREEN}✓${NC} Set GitHub secret: KONNECT_TOKEN" || \
                        echo -e "${YELLOW}⚠${NC} Failed to set KONNECT_TOKEN (may already exist)"
                fi
                
                if [ ! -z "$ARM_ACCESS_KEY" ]; then
                    gh secret set ARM_ACCESS_KEY --body "$ARM_ACCESS_KEY" 2>/dev/null && \
                        echo -e "${GREEN}✓${NC} Set GitHub secret: ARM_ACCESS_KEY" || \
                        echo -e "${YELLOW}⚠${NC} Failed to set ARM_ACCESS_KEY (may already exist)"
                fi
                
                echo ""
                echo -e "${CYAN}Next Steps:${NC}"
                echo -e "  1. Run Stage 1 - Platform:"
                echo -e "     ${YELLOW}gh workflow run stage1-platform.yml${NC}"
                echo -e "  2. Watch the workflow: ${YELLOW}gh run watch${NC}"
                echo -e "  3. Or run all stages:"
                echo -e "     ${YELLOW}gh workflow run deploy-all-stages.yml${NC}"
                echo ""
                echo -e "${CYAN}Workflows available:${NC}"
                echo -e "  • stage1-platform.yml       (Control Plane)"
                echo -e "  • stage2-integration.yml    (Gateway Service)"
                echo -e "  • stage3-api-spec-testing.yml (API Validation)"
                echo -e "  • stage4-api-product.yml    (API Catalog)"
                echo -e "  • stage5-developer-portal.yml (Developer Portal)"
                echo -e "  • deploy-all-stages.yml     (Run all stages)"
                echo ""
                echo -e "${CYAN}To destroy infrastructure:${NC}"
                echo -e "  ${YELLOW}gh workflow run destroy-all-stages.yml${NC}"
                
            else
                echo -e "${RED}✗${NC} Not a git repository"
                echo -e "   ${YELLOW}Initialize git first:${NC} git init"
            fi
        else
            echo -e "${YELLOW}⚠${NC} GitHub CLI not installed"
            echo -e "   ${YELLOW}Install with:${NC} brew install gh"
            echo -e "   ${YELLOW}Workflows already exist in:${NC} .github/workflows/stage*.yml"
        fi
        
        echo ""
    else
        echo -e "${CYAN}Next Steps:${NC}"
        echo -e "  1. Review backend selection: ${YELLOW}$BACKEND_SELECTED${NC}"
        echo -e "  2. Start with Stage 1: ${YELLOW}cd terraform/stages/1-platform && ./demo.sh${NC}"
        echo ""
        echo -e "${CYAN}Documentation:${NC}"
        echo -e "  - Backend setup: ${YELLOW}terraform/BACKEND-CONFIG.md${NC}"
        echo -e "  - Demo guide: ${YELLOW}README.md${NC}"
        echo ""
    fi
    exit 0
else
    echo -e "${RED}✗ Environment setup incomplete${NC}"
    echo ""
    echo -e "${YELLOW}Please resolve the failed checks above before proceeding.${NC}"
    echo ""
    echo -e "${CYAN}Quick Setup Guide:${NC}"
    echo -e "  1. Install missing tools (see install commands above)"
    echo -e "  2. Set KONNECT_TOKEN: ${YELLOW}export KONNECT_TOKEN='your-token'${NC}"
    echo -e "  3. Configure cloud backend (AWS or Azure)"
    echo -e "     - AWS: ${YELLOW}export AWS_ACCESS_KEY_ID='...' AWS_SECRET_ACCESS_KEY='...'${NC}"
    echo -e "     - Azure: ${YELLOW}az login${NC} or ${YELLOW}export ARM_ACCESS_KEY='...'${NC}"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  - Full setup guide: ${YELLOW}terraform/BACKEND-CONFIG.md${NC}"
    echo ""
    exit 1
fi
