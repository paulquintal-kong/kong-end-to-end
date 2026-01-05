#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}FHIR Server Demo Startup Script${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

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
while ! docker-compose ps | grep -q "healthy"; do
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

# Final status check
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Startup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "FHIR Server Status:"
docker-compose ps
echo ""
echo -e "${GREEN}Access Points:${NC}"
echo -e "  • FHIR API: ${YELLOW}http://localhost:8080/fhir${NC}"
echo -e "  • Web UI:   ${YELLOW}http://localhost:8080${NC}"
echo ""
echo -e "${GREEN}Useful Commands:${NC}"
echo -e "  • View logs:        ${YELLOW}docker-compose logs -f${NC}"
echo -e "  • Stop server:      ${YELLOW}docker-compose down${NC}"
echo -e "  • Restart server:   ${YELLOW}docker-compose restart${NC}"
echo -e "  • Stop Colima:      ${YELLOW}colima stop${NC}"
echo ""
echo -e "${GREEN}Test the server:${NC}"
echo -e "  ${YELLOW}curl http://localhost:8080/fhir/metadata${NC}"
echo ""
