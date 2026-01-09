#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
RESTART=false
if [ "$1" == "restart" ] || [ "$1" == "--restart" ] || [ "$1" == "-r" ]; then
    RESTART=true
fi

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}FHIR Server Demo Startup Script${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

if [ "$RESTART" = true ]; then
    echo -e "${YELLOW}Restart mode enabled${NC}"
    echo ""
fi

# Check if Colima is installed
if ! command -v colima &> /dev/null; then
    echo -e "${RED}Error: Colima is not installed${NC}"
    echo "Install it with: brew install colima"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Install it with: brew install docker docker-compose"
    exit 1
fi

# Check if Colima is already running
echo -e "${YELLOW}Checking Colima status...${NC}"
if colima status &> /dev/null; then
    echo -e "${GREEN}✓ Colima is already running${NC}"
else
    echo -e "${YELLOW}Starting Colima...${NC}"
    colima start --cpu 2 --memory 4
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Colima started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start Colima${NC}"
        exit 1
    fi
fi

# Wait for Docker to be ready
echo -e "${YELLOW}Waiting for Docker to be ready...${NC}"
timeout=30
counter=0
while ! docker info &> /dev/null; do
    sleep 1
    counter=$((counter + 1))
    if [ $counter -ge $timeout ]; then
        echo -e "${RED}✗ Docker failed to start within ${timeout} seconds${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ Docker is ready${NC}"

# Handle restart if requested
if [ "$RESTART" = true ]; then
    echo -e "${YELLOW}Stopping existing containers and ngrok tunnel...${NC}"
    
    # Stop ngrok if running
    if [ -f ".ngrok.pid" ]; then
        NGROK_PID=$(cat .ngrok.pid)
        if kill -0 $NGROK_PID 2>/dev/null; then
            kill $NGROK_PID 2>/dev/null
            echo -e "${GREEN}✓ Ngrok tunnel stopped${NC}"
        fi
        rm -f .ngrok.pid
    fi
    
    # Stop Docker containers
    docker-compose down
    echo -e "${GREEN}✓ Containers stopped${NC}"
    echo ""
fi

# Check if containers are already running
CONTAINER_RUNNING=$(docker-compose ps -q 2>/dev/null)
if [ ! -z "$CONTAINER_RUNNING" ] && [ "$RESTART" = false ]; then
    echo -e "${GREEN}✓ FHIR Server is already running${NC}"
    echo ""
    
    # Check if ngrok is also running
    if [ -f ".ngrok.pid" ]; then
        NGROK_PID=$(cat .ngrok.pid)
        if kill -0 $NGROK_PID 2>/dev/null; then
            echo -e "${GREEN}✓ Ngrok tunnel is already running${NC}"
            
            # Get existing ngrok URL
            if [ -f ".ngrok-url.txt" ]; then
                EXISTING_URL=$(cat .ngrok-url.txt)
                echo -e "${GREEN}✓ Ngrok URL: ${YELLOW}${EXISTING_URL}${NC}"
                echo ""
                echo -e "${BLUE}Tip: Use './start_demo.sh restart' to restart everything${NC}"
                echo ""
                exit 0
            fi
        fi
    fi
    
    echo -e "${YELLOW}Ngrok tunnel not found, will start it now...${NC}"
    echo ""
    # Continue to start ngrok below
else
    # Start the FHIR server
    echo -e "${YELLOW}Starting FHIR Server...${NC}"
    docker-compose up -d

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ FHIR Server container started${NC}"
    else
        echo -e "${RED}✗ Failed to start FHIR Server${NC}"
        exit 1
    fi

    # Wait for the server to be healthy
    echo -e "${YELLOW}Waiting for FHIR Server to be ready (this may take up to 60 seconds)...${NC}"
    timeout=90
    counter=0
    while ! curl -sf http://localhost:8080/fhir/metadata > /dev/null 2>&1; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            echo -e "${YELLOW}⚠ Server is taking longer than expected to start${NC}"
            echo -e "${YELLOW}Check logs with: docker-compose logs -f${NC}"
            break
        fi
        # Show progress
        if [ $((counter % 10)) -eq 0 ]; then
            echo -e "${YELLOW}  Still waiting... (${counter}s)${NC}"
        fi
    done
    echo -e "${GREEN}✓ FHIR Server is ready${NC}"
    echo ""
fi

# Check if ngrok is installed
echo -e "${BLUE}Checking for ngrok...${NC}"
if ! command -v ngrok &> /dev/null; then
    echo -e "${YELLOW}ngrok not found. Installing via Homebrew...${NC}"
    brew install ngrok/ngrok/ngrok
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install ngrok. Please install manually: https://ngrok.com/download${NC}"
        exit 1
    fi
fi

# Start ngrok tunnel
echo -e "${BLUE}Starting ngrok tunnel...${NC}"
ngrok http 8080 --log=stdout > .ngrok.log 2>&1 &
NGROK_PID=$!
echo $NGROK_PID > .ngrok.pid

# Wait for ngrok to start and get the public URL
echo -e "${BLUE}Waiting for ngrok tunnel to establish...${NC}"
sleep 3

# Get ngrok public URL from API
NGROK_URL=""
for i in {1..10}; do
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | head -1 | cut -d'"' -f4)
    if [ ! -z "$NGROK_URL" ]; then
        break
    fi
    echo -e "${YELLOW}Waiting for ngrok...${NC}"
    sleep 2
done

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}Failed to get ngrok URL. Check .ngrok.log for details${NC}"
    exit 1
fi

# Save ngrok URL to file for CI/CD and other tools
echo "$NGROK_URL/fhir" > .ngrok-url.txt
echo -e "${GREEN}✓ Ngrok tunnel established${NC}"

# Update ngrok URL in Insomnia workspace
echo -e "${BLUE}Updating Insomnia workspace with ngrok URL...${NC}"

INSOMNIA_WORKSPACE=".insomnia/fhir-api-insomnia.yaml"
if [ -f "$INSOMNIA_WORKSPACE" ]; then
    # Extract hostname from ngrok URL (remove https://)
    NGROK_HOST=$(echo "$NGROK_URL" | sed 's|https://||')
    
    # Update both local and CI environments in the workspace
    # Using awk for precise control - only update host/scheme in data sections
    awk -v host="$NGROK_HOST" '
    BEGIN { in_local=0; in_ci=0; in_data=0 }
    
    # Track OpenAPI env
    /- name: OpenAPI env localhost:8080/ { in_local=1; print; next }
    in_local && /- name: CI/ { in_local=0 }
    in_local && /^      data:/ { in_data=1; print; next }
    in_local && in_data && /^    - name:/ { in_data=0; in_local=0 }
    in_local && in_data && /^        host:/ && !/oauth/ { print "        host: " host; next }
    in_local && in_data && /^        scheme:/ { print "        scheme: https"; next }
    
    # Track CI env
    /- name: CI/ { in_ci=1; print; next }
    in_ci && /^spec:/ { in_ci=0 }
    in_ci && /^      data:/ { in_data=1; print; next }
    in_ci && in_data && /^spec:/ { in_data=0; in_ci=0 }
    in_ci && in_data && /^        host:/ && !/oauth/ { print "        host: " host; next }
    in_ci && in_data && /^        scheme:/ { print "        scheme: https"; next }
    
    {print}
    ' "$INSOMNIA_WORKSPACE" > "${INSOMNIA_WORKSPACE}.tmp"
    mv "${INSOMNIA_WORKSPACE}.tmp" "$INSOMNIA_WORKSPACE"
    
    echo -e "${GREEN}✓ Updated Insomnia workspace with ngrok URL${NC}"
else
    echo -e "${YELLOW}⚠ Insomnia workspace file not found, skipping update${NC}"
fi

echo ""

# Update Terraform variables with ngrok URL
echo -e "${BLUE}Updating Terraform variables with ngrok URL...${NC}"
TERRAFORM_TFVARS="terraform/terraform.tfvars"
if [ -d "terraform" ]; then
    cat > "$TERRAFORM_TFVARS" << EOF
# Auto-generated by start_demo.sh - DO NOT EDIT MANUALLY
# This file is regenerated each time start_demo.sh runs with the current ngrok URL

fhir_server_url = "${NGROK_URL}/fhir"
EOF
    echo -e "${GREEN}✅ Terraform variables updated: ${TERRAFORM_TFVARS}${NC}"
else
    echo -e "${YELLOW}⚠ Terraform directory not found, skipping Terraform variables update${NC}"
fi

echo ""

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}🚀 FHIR Server Ready!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo -e "${GREEN}Local Access:${NC}"
echo -e "  • FHIR Endpoint:    ${YELLOW}http://localhost:8080/fhir${NC}"
echo -e "  • Metadata:         ${YELLOW}http://localhost:8080/fhir/metadata${NC}"
echo ""
echo -e "${GREEN}Public Access (ngrok tunnel):${NC}"
echo -e "  • FHIR Endpoint:    ${YELLOW}${NGROK_URL}/fhir${NC}"
echo -e "  • Metadata:         ${YELLOW}${NGROK_URL}/fhir/metadata${NC}"
echo -e "  • Ngrok Dashboard:  ${YELLOW}http://localhost:4040${NC}"
echo ""
echo -e "${BLUE}Kong Gateway Data Plane (optional):${NC}"
echo -e "  To set up Kong Gateway data plane connected to Konnect:"
echo -e "  ${YELLOW}./setup_kong_dataplane.sh${NC}"
echo ""
echo -e "${GREEN}Useful Commands:${NC}"
echo -e "  • View logs:        ${YELLOW}docker-compose logs -f${NC}"
echo -e "  • Stop server:      ${YELLOW}docker-compose down${NC}"
echo -e "  • Stop ngrok:       ${YELLOW}kill \$(cat .ngrok.pid)${NC}"
echo -e "  • Restart server:   ${YELLOW}docker-compose restart${NC}"
echo -e "  • Stop Colima:      ${YELLOW}colima stop${NC}"
echo ""
echo -e "${GREEN}Test the server:${NC}"
echo -e "  • Local:  ${YELLOW}curl http://localhost:8080/fhir/metadata${NC}"
echo -e "  • Public: ${YELLOW}curl ${NGROK_URL}/fhir/metadata${NC}"
echo ""
echo -e "${BLUE}For CI/CD testing:${NC}"
echo -e "  • Ngrok URL is saved in .ngrok-url.txt"
echo -e "  • Insomnia workspace updated with ngrok URL"
echo -e "  • Commit .ngrok-url.txt and Insomnia workspace to enable CI/CD testing"
echo ""
echo -e "${BLUE}To restart everything:${NC}"
echo -e "  • Run: ${YELLOW}./start_demo.sh restart${NC}"
echo ""
