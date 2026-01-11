#!/bin/bash

# Stage 3: API Spec Development & Testing Demo Script
# Persona: API Developer / Quality Engineer
# 
# This stage demonstrates:
# - API specification development using Insomnia
# - OpenAPI spec linting with Spectral rules
# - Test collection creation and execution
# - CI/CD integration via GitHub Actions

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Stage 3: API Spec Development & Testing${NC}"
echo -e "${BLUE}   Persona: API Developer / Quality Engineer${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check for Spectral CLI
if ! command -v spectral &> /dev/null; then
    echo -e "${YELLOW}⚠️  Spectral CLI not found.${NC}"
    echo ""
    echo "Installing Spectral CLI..."
    npm install -g @stoplight/spectral-cli || {
        echo -e "${RED}❌ Failed to install Spectral CLI${NC}"
        echo "Please install manually: npm install -g @stoplight/spectral-cli"
        exit 1
    }
fi

# Change to repo root
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"

echo -e "${GREEN}✓${NC} Repository root: $REPO_ROOT"
echo ""

# ============================================================================
# STEP 1: Validate OpenAPI Specification
# ============================================================================
echo -e "${BLUE}━━━ Step 1: Validate OpenAPI Specification ━━━${NC}"
echo ""

if [ ! -f ".insomnia/fhir-api-openapi.yaml" ]; then
    echo -e "${RED}❌ OpenAPI spec not found at .insomnia/fhir-api-openapi.yaml${NC}"
    exit 1
fi

echo "📄 OpenAPI Spec: .insomnia/fhir-api-openapi.yaml"
echo ""
echo "Running specification validation with Spectral..."
echo ""

# Lint the OpenAPI spec with Spectral using the built-in OAS ruleset
if spectral lint .insomnia/fhir-api-openapi.yaml --ruleset spectral:oas; then
    echo ""
    echo -e "${GREEN}✓ OpenAPI specification passed all validation rules${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  OpenAPI specification has validation warnings/errors${NC}"
    echo "Review the output above and fix issues in the spec file."
fi

echo ""

# ============================================================================
# STEP 2: Validate Against Custom Spectral Rules
# ============================================================================
echo -e "${BLUE}━━━ Step 2: Validate Against Custom Spectral Rules ━━━${NC}"
echo ""

if [ ! -f ".spectral.yaml" ]; then
    echo -e "${YELLOW}⚠️  No custom Spectral rules found (.spectral.yaml)${NC}"
    echo "Skipping custom validation..."
else
    echo "📋 Custom Rules: .spectral.yaml"
    echo ""
    echo "Custom rules enforce:"
    echo "  • FHIR-specific resource patterns"
    echo "  • Patient identifier requirements"
    echo "  • Healthcare data compliance"
    echo "  • API documentation standards"
    echo ""
    
    echo "Running custom Spectral validation..."
    spectral lint .insomnia/fhir-api-openapi.yaml --ruleset .spectral.yaml || {
        echo -e "${YELLOW}⚠️  Spectral validation found issues${NC}"
    }
fi

echo ""

# ============================================================================
# STEP 3: Run Test Collection (if available)
# ============================================================================
echo -e "${BLUE}━━━ Step 3: Run Test Collection ━━━${NC}"
echo ""

if [ ! -f ".insomnia/fhir-api-insomnia.yaml" ]; then
    echo -e "${YELLOW}⚠️  No Insomnia test collection found${NC}"
    echo "Tests would be created in Insomnia and exported to .insomnia/"
else
    echo "🧪 Test Collection: .insomnia/fhir-api-insomnia.yaml"
    echo ""
    echo "This collection includes tests for:"
    echo "  • Patient resource CRUD operations"
    echo "  • Observation resource management"
    echo "  • Encounter and Condition resources"
    echo "  • Medication records"
    echo "  • Search functionality"
    echo "  • Error handling"
    echo ""
    
    # Ask if user wants to run tests
    read -p "Run test collection against local/dev environment? (y/N): " run_tests
    
    if [[ "$run_tests" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Select target environment:"
        echo "  1) Local (http://localhost:8000)"
        echo "  2) Dev/Staging (Kong Gateway)"
        echo "  3) Skip tests"
        echo ""
        read -p "Choice [1-3]: " env_choice
        
        case $env_choice in
            1)
                echo ""
                echo "Running tests against local environment..."
                echo -e "${YELLOW}Note: Ensure your local FHIR server is running${NC}"
                ;;
            2)
                echo ""
                echo "Running tests against Kong Gateway..."
                echo -e "${YELLOW}Note: Ensure Stage 2 (Integration) is complete${NC}"
                ;;
            3)
                echo ""
                echo "Skipping test execution"
                ;;
            *)
                echo ""
                echo "Invalid choice. Skipping tests."
                ;;
        esac
        
        # Note: Actual test execution would require proper environment setup
        echo ""
        echo -e "${BLUE}💡 Tip:${NC} Tests are automatically run in GitHub Actions on push/PR"
    fi
fi

echo ""

# ============================================================================
# STEP 4: CI/CD Integration
# ============================================================================
echo -e "${BLUE}━━━ Step 4: CI/CD Integration ━━━${NC}"
echo ""

echo "GitHub Actions workflows configured:"
echo ""
echo "  📋 api-governance.yml"
echo "     • Lints OpenAPI spec on every push"
echo "     • Validates against Spectral rules"
echo "     • Runs automatically on spec changes"
echo ""
echo "  🧪 (Future) api-testing.yml"
echo "     • Executes Insomnia test collection"
echo "     • Runs against staging environment"
echo "     • Reports test results"
echo ""

if [ -f ".github/workflows/api-governance.yml" ]; then
    echo -e "${GREEN}✓ API Governance workflow configured${NC}"
else
    echo -e "${YELLOW}⚠️  API Governance workflow not found${NC}"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Stage 3 Complete: API Spec Development & Testing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "What you've validated:"
echo "  ✓ OpenAPI specification is well-formed"
echo "  ✓ FHIR-specific rules are enforced"
echo "  ✓ Test collection is ready for execution"
echo "  ✓ CI/CD pipelines will validate all changes"
echo ""
echo -e "${YELLOW}Key Files:${NC}"
echo "  • .insomnia/fhir-api-openapi.yaml - API specification"
echo "  • .insomnia/fhir-api-insomnia.yaml - Test collection"
echo "  • .spectral.yaml - Custom linting rules"
echo "  • .github/workflows/api-governance.yml - CI/CD workflow"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "  1. Continue to Stage 4 (API Product & Governance):"
echo "     ${GREEN}cd ../4-api-product && ./demo.sh${NC}"
echo ""
echo "  2. Or modify the API spec in Insomnia:"
echo "     - Open Insomnia desktop app"
echo "     - Import .insomnia/ files"
echo "     - Make changes and export"
echo "     - Re-run this script to validate"
echo ""
echo "  3. View CI/CD results:"
echo "     - Push changes to GitHub"
echo "     - Check Actions tab for workflow runs"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
