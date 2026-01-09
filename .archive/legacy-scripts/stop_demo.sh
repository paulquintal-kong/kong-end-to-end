#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}================================${NC}"
echo -e "${RED}FHIR Server Demo Shutdown Script${NC}"
echo -e "${RED}================================${NC}"
echo ""

# Stop ngrok tunnel
echo -e "${YELLOW}Stopping ngrok tunnel...${NC}"
if [ -f ".ngrok.pid" ]; then
    NGROK_PID=$(cat .ngrok.pid)
    if kill -0 $NGROK_PID 2>/dev/null; then
        kill $NGROK_PID 2>/dev/null
        echo -e "${GREEN}✓ Ngrok tunnel stopped${NC}"
    else
        echo -e "${YELLOW}⚠ Ngrok process not found${NC}"
    fi
    rm -f .ngrok.pid
else
    echo -e "${YELLOW}⚠ No ngrok PID file found${NC}"
fi

# Clean up ngrok log file
if [ -f ".ngrok.log" ]; then
    rm -f .ngrok.log
    echo -e "${GREEN}✓ Cleaned up ngrok log file${NC}"
fi

echo ""

# Stop Docker containers
echo -e "${YELLOW}Stopping FHIR Server containers...${NC}"
if docker-compose ps -q 2>/dev/null | grep -q .; then
    docker-compose down
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ FHIR Server containers stopped${NC}"
    else
        echo -e "${RED}✗ Failed to stop containers${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ No containers are running${NC}"
fi

echo ""

# Stop Colima
echo -e "${YELLOW}Stopping Colima...${NC}"
if command -v colima &> /dev/null; then
    if colima status &> /dev/null; then
        colima stop
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Colima stopped${NC}"
        else
            echo -e "${RED}✗ Failed to stop Colima${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠ Colima is not running${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Colima not found${NC}"
fi

echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}✅ FHIR Demo Environment Stopped${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo -e "${BLUE}To start again:${NC}"
echo -e "  ${YELLOW}./start_demo.sh${NC}"
echo ""
