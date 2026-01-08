#!/bin/bash

# Kong Data Plane Setup Script
# Downloads cluster certificates from Konnect and starts the data plane

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}Kong Data Plane Setup${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""

# Check for required environment variable
if [ -z "$TF_VAR_konnect_pat" ]; then
    echo -e "${RED}✗ Error: TF_VAR_konnect_pat environment variable not set${NC}"
    echo "Please set your Kong Konnect PAT token:"
    echo "  export TF_VAR_konnect_pat=\"your-token-here\""
    exit 1
fi

# Get control plane ID from Terraform output
cd terraform
CONTROL_PLANE_ID=$(terraform output -json | jq -r '.control_plane_id.value')
cd ..

if [ -z "$CONTROL_PLANE_ID" ] || [ "$CONTROL_PLANE_ID" == "null" ]; then
    echo -e "${RED}✗ Error: Could not get control plane ID from Terraform${NC}"
    echo "Please run 'terraform apply' first"
    exit 1
fi

echo -e "${GREEN}✓ Control Plane ID: ${CONTROL_PLANE_ID}${NC}"

# Download cluster certificates from Konnect
echo -e "${YELLOW}Generating cluster certificates...${NC}"

# Create .kong directory if it doesn't exist
mkdir -p .kong

# Generate a self-signed certificate for the data plane
echo -e "${YELLOW}Generating self-signed certificate pair...${NC}"

openssl req -new -x509 -nodes \
  -newkey rsa:2048 \
  -keyout .kong/tls.key \
  -out .kong/tls.crt \
  -days 1095 \
  -subj "/CN=kong-dataplane/C=US"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate certificate${NC}"
    exit 1
fi

# Upload the certificate to Konnect
echo -e "${YELLOW}Uploading certificate to Konnect...${NC}"

# Read the certificate content
CERT_CONTENT=$(cat .kong/tls.crt)

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Bearer ${TF_VAR_konnect_pat}" \
    -H "Content-Type: application/json" \
    -d "{\"cert\": $(jq -Rs . <<< "$CERT_CONTENT")}" \
    "https://au.api.konghq.com/v2/control-planes/${CONTROL_PLANE_ID}/dp-client-certificates")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "201" ] && [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}✗ Failed to upload certificate (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
    exit 1
fi

# Verify files were created
if [ ! -f .kong/tls.crt ] || [ ! -f .kong/tls.key ]; then
    echo -e "${RED}✗ Failed to create certificate files${NC}"
    exit 1
fi

# Check if files are not empty
if [ ! -s .kong/tls.crt ] || [ ! -s .kong/tls.key ]; then
    echo -e "${RED}✗ Certificate files are empty${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Certificates generated and uploaded successfully${NC}"
echo -e "${GREEN}  - Certificate: .kong/tls.crt${NC}"
echo -e "${GREEN}  - Private Key: .kong/tls.key${NC}"
echo ""

# Start Kong data plane
echo -e "${YELLOW}Starting Kong Gateway data plane...${NC}"
docker-compose up -d kong-gateway

echo ""
echo -e "${GREEN}✓ Kong Gateway data plane is starting${NC}"
echo ""
echo -e "${YELLOW}Waiting for Kong Gateway to be ready...${NC}"

# Wait for Kong to be ready
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:8000 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Kong Gateway is ready!${NC}"
        echo ""
        echo -e "${GREEN}Data plane is now connected to Konnect Control Plane${NC}"
        echo -e "${GREEN}Proxy is listening on: http://localhost:8000${NC}"
        echo ""
        echo "You can now configure routes and services in Konnect, and they will"
        echo "be automatically synchronized to this data plane."
        echo ""
        echo "To view logs:"
        echo "  docker logs -f kong-dataplane"
        echo ""
        exit 0
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 2
    echo -n "."
done

echo ""
echo -e "${RED}✗ Kong Gateway did not become ready within expected time${NC}"
echo "Check logs with: docker logs kong-dataplane"
exit 1
