# Kong API Lifecycle Demo

[![Kong Konnect](https://img.shields.io/badge/Kong-Konnect-00ADD8?logo=kong)](https://konghq.com/products/kong-konnect)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![FHIR R4](https://img.shields.io/badge/FHIR-R4-ED1C24?logo=hl7)](https://hl7.org/fhir/R4/)

> A comprehensive, persona-based demonstration of the complete API lifecycle using Kong Konnect. This repository showcases how different teams collaborate—from infrastructure provisioning to developer consumption—using Infrastructure as Code.

## Overview

This demonstration walks through the **four stages of API delivery**, each representing a different team's responsibilities in the API lifecycle. Built with a real FHIR R4 healthcare API, it demonstrates enterprise-grade API management practices.

### What You'll Learn

- **Infrastructure as Code**: Complete API platform provisioned via Terraform
- **Multi-Persona Workflow**: How Platform, Integration, and API teams collaborate  
- **API Governance**: Rate limiting, catalog management, and policy enforcement
- **Developer Experience**: Self-service portal with auto-generated documentation
- **Real-world Scenario**: Healthcare API (FHIR R4) with OpenAPI specification

### Demo Stages

| Stage | Persona | Responsibility | Duration |
|-------|---------|----------------|----------|
| **1. Platform** | Platform Engineer | Provision Kong infrastructure | 2 min |
| **2. Integration** | Integration Engineer | Connect backend APIs to gateway | 5 min |
| **3. API Spec & Testing** | API Developer / QA | Validate specs, linting, testing | 5 min |
| **4. API Product** | API Owner | Add governance & publish to catalog | 8 min |
| **5. Dev Portal** | API Owner | Create developer portal | 3 min |
| **6. Consumption** | 3rd Party Developer | Discover and consume APIs | 5 min |

**Total**: 25-30 minutes for complete lifecycle demonstration

---

## Prerequisites

Before running the demo, ensure you have:

- **Kong Konnect Account**: [Sign up for free](https://konghq.com/products/kong-konnect/register) (AU region)
- **Personal Access Token**: Generate from [Account Settings](https://cloud.konghq.com/global/account/tokens)
- **Terraform**: Version 1.0 or higher ([Install](https://www.terraform.io/downloads))
- **Backend API**: FHIR server or use the provided default endpoint
- **Azure Account**: For Terraform state storage (Azure Storage backend)

---

## Quick Start

### 1. Initialize Demo Environment

**Run the initialization script first** to verify your environment:

```bash
./init-demo.sh
```

This script automatically checks:
- ✅ Required CLI tools (terraform, jq, curl, docker)
- ✅ Optional tools (gh, aws, az, ngrok)
- ✅ Environment variables (KONNECT_TOKEN)
- ✅ Cloud backend configuration (AWS S3 or Azure Storage)
- ✅ Terraform backend files
- ✅ Docker daemon status

**Setup instructions** if checks fail:
```bash
# Set Kong Konnect token
export KONNECT_TOKEN="your-personal-access-token-here"

# Configure cloud backend (choose one):
# AWS:
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# OR Azure:
az login
# or export ARM_ACCESS_KEY="your-storage-key"
```

See [terraform/BACKEND-CONFIG.md](terraform/BACKEND-CONFIG.md) for detailed backend setup.

---

### 2. Run the Complete Demo

```bash
# Run each stage sequentially
cd terraform/stages/1-platform && ./demo.sh
cd ../2-integration && ./demo.sh
cd ../3-api-spec-testing && ./demo.sh
cd ../4-api-product && ./demo.sh
cd ../5-developer-portal && ./demo.sh

# Open the developer portal
# URL provided in Stage 5 output
```

Each `demo.sh` script:
- ✅ Loads outputs from previous stages automatically
- ✅ Prompts for configuration options interactively
- ✅ Shows planned changes before applying
- ✅ Provides clear next steps

### What Gets Created

After running all stages, you'll have:

- **Control Plane**: Kong Gateway management layer
- **Gateway Service**: Connected to your backend API
- **API Route**: Public endpoint for API access
- **Validated API Spec**: Linted OpenAPI spec with custom healthcare rules
- **Test Collection**: Automated API tests in Insomnia
- **Catalog Entry**: API published with OpenAPI specification
- **Rate Limiting**: 5 requests per minute enforcement
- **Developer Portal**: Self-service portal with live documentation
- **CI/CD Pipeline**: Automated spec validation on every commit

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       KONG KONNECT                           │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  Control   │  │  Catalog   │  │  Developer │            │
│  │   Plane    │  │  Service   │  │   Portal   │            │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘            │
│        │                │                │                   │
│        └────────────────┴────────────────┘                   │
│                         │                                    │
│              ┌──────────▼──────────┐                         │
│              │   Gateway Service   │                         │
│              │  • Rate Limiting    │                         │
│              │  • Auth (optional)  │                         │
│              │  • CORS (optional)  │                         │
│              └──────────┬──────────┘                         │
└─────────────────────────┼──────────────────────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │  Backend API     │
                │  (FHIR Server)   │
                └──────────────────┘
```

---

## Stage-by-Stage Guide

### Stage 1: Platform Engineer

**Goal**: Provision Kong Gateway infrastructure  
**Time**: 2 minutes  
**Location**: `terraform/stages/1-platform/`

#### What It Does
- Creates Kong Gateway Control Plane
- Establishes infrastructure foundation
- Configures platform-level settings

#### Run the Stage

```bash
cd terraform/stages/1-platform
./demo.sh
```

#### Expected Output
```
control_plane_id = "8cbf1a92-acae-48df-9e08-939c67d3aed1"
control_plane_endpoint = "https://[id].au.cp0.konghq.com"
```

#### Validation
- ✅ Control Plane visible in [Konnect UI](https://au.cloud.konghq.com)
- ✅ `stage1-outputs.json` created for Stage 2

---

### Stage 2: Integration Engineer

**Goal**: Connect backend API to Kong Gateway  
**Time**: 5 minutes  
**Location**: `terraform/stages/2-integration/`  
**Dependencies**: Stage 1 outputs

#### What It Does
- Configures Gateway Service (upstream connection)
- Creates API routes and traffic rules
- Sets up public API endpoints

#### Run the Stage

```bash
cd terraform/stages/2-integration
./demo.sh
```

When prompted:
- **Backend API URL**: Press Enter for default or provide your FHIR server URL

#### Expected Output
```
service_id = "0cf7912f-c8fa-472e-9fc1-7b139c0a2f91"
api_endpoint = "https://[cp-id].au.cp0.konghq.com/api/patients"
```

#### Validation

Test the API endpoint:
```bash
curl https://[cp-id].au.cp0.konghq.com/api/patients
```

Expected: HTTP 200 with FHIR Patient bundle response

---

### Stage 3: API Owner (Productization)

**Goal**: Publish API to catalog and add governance policies  
**Time**: 8 minutes  
**Location**: `terraform/stages/3-api-product/`  
**Dependencies**: Stage 1 & 2 outputs

#### What It Does
- Publishes API to Kong Catalog
- Uploads OpenAPI specification
- Implements rate limiting (5 requests/minute)
- Links API to gateway service

#### Run the Stage

```bash
cd terraform/stages/3-api-product
./demo.sh
```

When prompted:
- **Rate Limit**: Enter desired requests per minute (default: 5)

#### Expected Output
```
catalog_api_id = "f8abc7a8-7641-43e0-b83d-98d292bd4763"
rate_limit_plugin_id = "f67fa3a5-286b-42a0-9646-fd7397ec947e"
```

#### Validation

**Test Rate Limiting** (Demo Highlight):

```bash
# Get API endpoint from Stage 2
API_URL=$(cd ../2-integration && terraform output -raw api_endpoint)

# Make 6 requests - the 6th will fail!
for i in {1..6}; do
  echo "═══ Request $i ═══"
  curl -i "$API_URL" 2>/dev/null | grep -E "HTTP|RateLimit"
  sleep 1
done
```

**Expected Results**:
- Requests 1-5: `HTTP/2 200` with `X-RateLimit-Remaining` headers
- Request 6: `HTTP/2 429` (Too Many Requests) ← **Governance in action!**

**View in Konnect UI**:
- Navigate to [Catalog](https://au.cloud.konghq.com/catalog)
- See "Patient Records API" with OpenAPI specification
- View rate limiting plugin configuration

---

### Stage 2.5: API Developer / Quality Engineer

**Goal**: Validate API specifications and run tests  
**Time**: 5-10 minutes  
**Location**: `terraform/stages/2.5-api-spec-testing/`  
**Dependencies**: Stage 2 outputs

#### What It Does
- Validates OpenAPI specification syntax
- Enforces FHIR-specific linting rules (Spectral)
- Shows Insomnia test collection structure
- Demonstrates CI/CD integration for automated validation

#### Run the Stage

```bash
cd terraform/stages/3-api-spec-testing
./demo.sh
```

#### Expected Output
```
═══════════════════════════════════════════════════════════════
   Stage 3: API Spec Development & Testing
   Persona: API Developer / Quality Engineer
═══════════════════════════════════════════════════════════════

━━━ Step 1: Validate OpenAPI Specification ━━━
✓ OpenAPI specification passed all linting rules

━━━ Step 2: Validate Against Custom Spectral Rules ━━━
✓ All custom rules passed

━━━ Step 3: Run Test Collection ━━━
🧪 Test Collection includes 50+ test cases

━━━ Step 4: CI/CD Integration ━━━
✓ API Governance workflow configured
```

#### Validation

**Verify Spec Linting**:
```bash
inso lint spec .insomnia/fhir-api-openapi.yaml
```

**Check Custom Rules**:
```bash
spectral lint .insomnia/fhir-api-openapi.yaml
```

**View Test Collection**:
- Open [`.insomnia/fhir-api-insomnia.yaml`](.insomnia/fhir-api-insomnia.yaml)
- See 50+ test cases for Patient, Observation, Encounter resources

**CI/CD Integration**:
- Every push to `main` triggers [api-governance.yml](.github/workflows/api-governance.yml)
- OpenAPI spec automatically linted
- Spectral rules validated
- Test collection validated
- Failures block merge

**What Gets Validated**:
- ✅ OpenAPI 3.1 syntax correctness
- ✅ FHIR resource structure compliance
- ✅ Patient identifier requirements
- ✅ Healthcare domain rules
- ✅ API documentation standards

---

### Stage 4: API Owner (Productization)

**Goal**: Publish API to catalog and add governance policies  
**Time**: 8 minutes  
**Location**: `terraform/stages/4-api-product/`  
**Dependencies**: Stage 1 & 2 outputs

#### What It Does
- Publishes API to Kong Catalog
- Uploads OpenAPI specification
- Implements rate limiting (5 requests/minute)
- Links API to gateway service

#### Run the Stage

```bash
cd terraform/stages/4-api-product
./demo.sh
```

When prompted:
- **Rate Limit**: Enter desired requests per minute (default: 5)

#### Expected Output
```
catalog_api_id = "f8abc7a8-7641-43e0-b83d-98d292bd4763"
rate_limit_plugin_id = "f67fa3a5-286b-42a0-9646-fd7397ec947e"
```

#### Validation

**Test Rate Limiting** (Demo Highlight):

```bash
# Get API endpoint from Stage 2
API_URL=$(cd ../2-integration && terraform output -raw api_endpoint)

# Make 6 requests - the 6th will fail!
for i in {1..6}; do
  echo "═══ Request $i ═══"
  curl -i "$API_URL" 2>/dev/null | grep -E "HTTP|RateLimit"
  sleep 1
done
```

**Expected Results**:
- Requests 1-5: `HTTP/2 200` with `X-RateLimit-Remaining` headers
- Request 6: `HTTP/2 429` (Too Many Requests) ← **Governance in action!**

**View in Konnect UI**:
- Navigate to [Catalog](https://au.cloud.konghq.com/catalog)
- See "Patient Records API" with OpenAPI specification
- View rate limiting plugin configuration

---

### Stage 5: API Owner (Developer Portal)

**Goal**: Create developer portal for external developers  
**Time**: 3 minutes  
**Location**: `terraform/stages/5-developer-portal/`  
**Dependencies**: Stage 4 outputs

#### What It Does
- Creates developer portal
- Publishes API for discovery
- Configures developer onboarding workflow

#### Run the Stage

```bash
cd terraform/stages/5-developer-portal
./demo.sh
```

When prompted:
- **Enable authentication?** `no` (public) or `yes` (private)
- **Auto-approve developers?** `no` (manual) or `yes` (self-service)

#### Expected Output
```
portal_url = "https://[domain].au.kongportals.com"
portal_id = "519551c7-565e-4031-bd8e-8e5d50af25f2"
```

The portal opens automatically in your browser!

#### Validation
- ✅ Portal loads in browser
- ✅ API documentation visible
- ✅ OpenAPI specification rendered
- ✅ Interactive API explorer available

---

### Stage 6: 3rd Party Developer (Manual)

**Goal**: Discover and consume APIs as an external developer  
**Time**: 5 minutes  
**Location**: Developer Portal (web UI)

#### What to Demonstrate

1. **Browse API Catalog**
   - Navigate to "APIs" section
   - View "Patient Records API"

2. **Read Documentation**
   - Explore auto-generated OpenAPI docs
   - Review endpoint descriptions
   - Check request/response schemas

3. **Register Account** (if auth enabled)
   - Click "Sign Up"
   - Complete registration form
   - Wait for approval (or instant if auto-approve enabled)

4. **Create Application**
   - Navigate to "My Apps"
   - Click "New Application"
   - Select "Patient Records API"

5. **Get Credentials**
   - Request API key or OAuth credentials
   - Copy credentials for testing

6. **Test API**
   ```bash
   curl -H "apikey: YOUR-API-KEY" \
     https://[cp-id].au.cp0.konghq.com/api/patients
   ```

7. **Observe Rate Limiting**
   - Make 6+ requests
   - See HTTP 429 error after 5 requests
   - View usage analytics in portal

---

## Configuration Options

### Portal Access Modes

Control how developers access your portal by configuring authentication settings in Stage 4.

#### Public Portal (Open Access)
Anyone can browse and read documentation without login. Best for public APIs and open-source projects.

```hcl
# When Stage 4 prompts:
Enable authentication? no
```

#### Private Portal (Controlled Access)
Login required to view portal. Admin manually approves each developer. Best for partner/B2B APIs.

```hcl
Enable authentication? yes
Auto-approve developers? no
```

#### Self-Service Portal
Login required but developers get instant access. Best for internal APIs and high developer velocity.

```hcl
Enable authentication? yes
Auto-approve developers? yes
```

### Rate Limiting Adjustment

Configure API rate limits in Stage 3 to control usage and prevent abuse.

```hcl
# When Stage 3 prompts:
API Rate Limit (requests per minute): 5  # Adjust as needed
```

Common configurations:
- **Development**: 100 requests/minute
- **Production (Free Tier)**: 5 requests/minute
- **Production (Paid)**: 1000 requests/minute

### Backend API Configuration

Point Kong Gateway to your own backend API in Stage 2.

```hcl
# When Stage 2 prompts:
Enter your backend API URL: https://your-fhir-server.com/fhir
```

Or use the default FHIR demo server (public endpoint).

---

## Demo Scenarios

### Scenario 1: Quick Demo (15 minutes)

**Goal**: Show key value propositions quickly  
**Best for**: Executive audiences, time-constrained meetings

1. **Pre-deploy Stage 1-2** before meeting (save 7 minutes)
2. **Focus on Stage 3** - Live rate limiting demo (8 min)
3. **Show Stage 4** - Portal walkthrough (5 min)
4. **Wrap up** - Q&A (2 min)

**Key Moments**:
- Trigger rate limiting by making 6 API calls
- Show auto-generated documentation in portal
- Demonstrate self-service developer onboarding

---

### Scenario 2: Full Lifecycle (30 minutes)

**Goal**: Complete end-to-end demonstration  
**Best for**: Technical audiences, POC kickoffs

Run all stages sequentially, highlighting:
1. **Infrastructure as Code** - Show Terraform applying changes
2. **Persona Handoffs** - Explain how teams collaborate
3. **Policy Enforcement** - Live rate limiting demo
4. **Developer Experience** - Full portal walkthrough

---

### Scenario 3: Governance Focus (20 minutes)

**Goal**: Emphasize API governance and policy management  
**Best for**: Enterprise architects, compliance teams

1. **Stage 1-2** - Quick overview (pre-deployed)
2. **Stage 3 Deep Dive** - Catalog management, specifications, rate limiting
3. **Policy Enforcement** - Demonstrate multiple governance policies
4. **Analytics** - Show usage monitoring in Konnect UI

**Additional Policies to Demo** (uncomment in Stage 3):
- CORS for browser-based apps
- API Key authentication
- Request transformation

---

## Troubleshooting

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| `Control Plane ID not found` | Stages run out of order | Run stages sequentially: 1→2→3→4→5 |
| `State blob is already locked` | Previous Terraform run not completed | `terraform force-unlock <lock-id>` |
| `inso: command not found` | Insomnia CLI not installed | `npm install -g @insomnia/inso` |
| `Spectral validation failed` | Custom rules not passing | Review `.spectral.yaml` and fix spec issues |
| `Rate limiting not working` | Request timing too slow | Make requests within 60 seconds |
| `Portal returns 404` | Portal still provisioning | Wait 60-90 seconds and retry |
| `HTTP 502 Bad Gateway` | Backend API unreachable | Verify upstream URL in Stage 2 |
| `Permission denied` | Invalid token or expired | Regenerate Personal Access Token |
| `GitHub Actions failing` | Spec changes broke validation | Run Stage 3 locally to debug |

### Debugging Tips

**View Terraform state**:
```bash
cd terraform/stages/[stage-name]
terraform show
```

**Check Kong Konnect UI**:
- Control Planes: https://au.cloud.konghq.com/gateway-manager
- API Catalog: https://au.cloud.konghq.com/catalog
- Developer Portal: https://au.cloud.konghq.com/portals

**Inspect plugin configuration**:
```bash
# Get plugin details
curl "https://au.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID/core-entities/plugins/$PLUGIN_ID" \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```

**Test API directly** (bypass rate limiting):
```bash
# Test upstream connection
curl "https://your-backend-api.com/fhir/Patient"
```

---

## Cleanup

### Remove All Resources

Destroy in **reverse order** to properly clean up dependencies:

```bash
# Stage 5: Developer Portal
cd terraform/stages/5-developer-portal
terraform destroy -auto-approve

# Stage 4: API Product
cd ../4-api-product
terraform destroy -auto-approve

# Stage 2: Integration
cd ../2-integration
terraform destroy -auto-approve

# Stage 1: Platform
cd ../1-platform
terraform destroy -auto-approve
```

### Cleanup Script

```bash
#!/bin/bash
# cleanup.sh - Remove all demo resources
for stage in 5-developer-portal 4-api-product 2-integration 1-platform; do
  echo "Destroying terraform/stages/$stage..."
  cd "terraform/stages/$stage"
  terraform destroy -auto-approve
  cd -
done
echo "✅ All resources destroyed"
```

### Clean Local Environment

```bash
# Stop FHIR server (if running)
docker-compose down

# Remove Docker volumes
docker volume prune -f

# Clean up Stage 3 test artifacts (optional)
cd terraform/stages/3-api-spec-testing
rm -f *.xml *.json 2>/dev/null
```

**Note**: Legacy monolithic Terraform files and old demo scripts have been archived in [`.archive/`](.archive/) directory. See [.archive/README.md](.archive/README.md) for migration details.
echo "✅ All resources destroyed"
```

---

## Repository Structure

```
kong-end-to-end/
├── README.md                           # This comprehensive guide
├── DEMO_GUIDE.md                       # Presales playbook & talking points
├── .insomnia/
│   ├── fhir-api-openapi.yaml          # OpenAPI 3.1 specification
│   └── fhir-api-insomnia.yaml         # Insomnia test collection
├── .spectral.yaml                      # Custom API linting rules (FHIR)
│
├── .github/
│   └── workflows/
│       ├── api-governance.yml          # Automated spec validation
│       └── README.md                   # Workflow documentation
│
├── terraform/
│   ├── stages/                         # Modular persona-based stages
│   │   ├── 1-platform/                 # Platform Engineer
│   │   │   ├── demo.sh                 # Interactive deployment script
│   │   │   ├── provider.tf             # Terraform provider config
│   │   │   ├── control_plane.tf        # Kong control plane resource
│   │   │   ├── variables.tf            # Input variables
│   │   │   └── outputs.tf              # Outputs for Stage 2
│   │   │
│   │   ├── 2-integration/              # Integration Engineer
│   │   │   ├── demo.sh
│   │   │   ├── gateway_service.tf      # Service & route configuration
│   │   │   ├── variables.tf            # Inputs from Stage 1
│   │   │   └── outputs.tf              # Outputs for Stage 3 & 4
│   │   │
│   │   ├── 3-api-spec-testing/         # API Developer / QA
│   │   │   ├── demo.sh                 # Spec validation script
│   │   │   └── README.md               # Testing guide
│   │   │
│   │   ├── 4-api-product/              # API Owner (Governance)
│   │   │   ├── demo.sh
│   │   │   ├── catalog.tf              # Catalog & API specification
│   │   │   ├── plugins.tf              # Rate limiting & policies
│   │   │   ├── variables.tf            # Inputs from Stage 1-2
│   │   │   └── outputs.tf              # Outputs for Stage 5
│   │   │
│   │   └── 5-developer-portal/         # API Owner (Publishing)
│   │       ├── demo.sh
│   │       ├── portal.tf               # Developer portal config
│   │       ├── variables.tf            # Inputs from Stage 4
│   │       └── outputs.tf              # Portal URL & settings
│   │
│   └── .archive/                       # Archived legacy files
│       ├── README.md                   # Archive documentation
│       ├── legacy-terraform/           # Original monolithic TF files
│       └── legacy-scripts/             # Original demo scripts
│
├── portal/                             # Exported portal content
│   ├── README.md                       # Portal management guide
│   └── portal-pages.json               # Portal page structure
│
└── .github/
    └── workflows/
        └── README.md                   # CI/CD workflow documentation
```

---

## Additional Resources

### Documentation
- **[DEMO_GUIDE.md](DEMO_GUIDE.md)** - Complete presales playbook with:
  - Detailed talking points by persona
  - Objection handling strategies
  - Demo variations and scenarios
  - Customer pain point mapping
  - Competitive differentiators

- **[portal/README.md](portal/README.md)** - Developer portal management:
  - Portal configuration details
  - Page structure and content
  - Publishing workflow
  - API product linking

- **[.github/workflows/README.md](.github/workflows/README.md)** - CI/CD workflows:
  - API governance automation
  - Spec linting and validation
  - Test execution
  - Quality gates

- **[terraform/stages/3-api-spec-testing/README.md](terraform/stages/3-api-spec-testing/README.md)** - API testing guide:
  - Insomnia CLI usage
  - Spectral rule configuration
  - Local test execution
  - CI/CD integration

### Kong Resources
- [Kong Konnect Documentation](https://docs.konghq.com/konnect/)
- [Terraform Provider Docs](https://registry.terraform.io/providers/Kong/konnect/latest/docs)
- [Kong Gateway Plugins](https://docs.konghq.com/hub/)
- [API Management Best Practices](https://konghq.com/learning-center/api-management/)

### API Development Tools
- [Insomnia CLI (inso) Documentation](https://docs.insomnia.rest/insomnia/inso-cli)
- [Spectral Linting Rules](https://meta.stoplight.io/docs/spectral/README.md)
- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)

### FHIR Resources
- [FHIR R4 Specification](https://hl7.org/fhir/R4/)
- [HAPI FHIR Server](https://hapifhir.io/)
- [HL7 FHIR Resources](https://www.hl7.org/fhir/)

---

## Key Features Demonstrated

### Infrastructure as Code
- ✅ Complete API platform defined in Terraform
- ✅ Version-controlled configuration
- ✅ Repeatable deployments across environments
- ✅ Automated dependency management between stages

### API Quality & Governance
- ✅ OpenAPI specification validation (Inso CLI)
- ✅ Custom linting rules (Spectral) for FHIR compliance
- ✅ Automated testing with Insomnia test collections
- ✅ CI/CD quality gates blocking bad specs
- ✅ Rate limiting enforcement (5 requests/minute)
- ✅ Catalog-based API discovery
- ✅ Policy-driven access control
- ✅ Service-level agreements (SLA) configuration

### Developer Experience
- ✅ Self-service developer portal
- ✅ Auto-generated API documentation
- ✅ Interactive API explorer
- ✅ Credential management
- ✅ Usage analytics and monitoring

### Enterprise Features
- ✅ Multi-environment support (dev/staging/prod)
- ✅ Role-based access control (RBAC)
- ✅ Audit logging and compliance
- ✅ Service mesh integration ready
- ✅ Analytics and observability

---

## Use Cases

This demonstration is applicable to multiple industries and scenarios:

### Healthcare (Current Example)
- **FHIR R4 APIs** for patient data exchange
- **HIPAA compliance** through governance policies
- **Partner integration** via private developer portal
- **Rate limiting** to protect PHI systems

### Financial Services
- **PSD2/Open Banking** API compliance
- **PCI-DSS** security requirements
- **Third-party developer** onboarding
- **Transaction rate limiting**

### Retail & E-commerce
- **Product catalog APIs** for marketplace partners
- **Inventory management** API governance
- **Third-party seller** integration
- **API monetization** preparation

### SaaS Platforms
- **Public API programs** for ecosystem partners
- **Developer community** building
- **API-first architecture** demonstration
- **Multi-tenant** API management

---

## Contributing

This demonstration is designed for flexibility and customization. To adapt for your use case:

1. **Replace the FHIR API** with your backend service
2. **Update OpenAPI specification** in `.insomnia/fhir-api-openapi.yaml`
3. **Customize rate limits** and policies in Stage 3
4. **Modify portal settings** in Stage 4
5. **Adjust labels and metadata** throughout for your domain

---

## Support

For questions or issues:

- **Kong Konnect**: [Kong Support](https://support.konghq.com/)
- **Terraform Provider**: [GitHub Issues](https://github.com/Kong/terraform-provider-konnect/issues)
- **Demo Setup**: Review [DEMO_GUIDE.md](DEMO_GUIDE.md) troubleshooting section

---

## License

This demonstration repository is provided as-is for educational and presales purposes.

---

**Ready to demonstrate enterprise-grade API management!** 🚀

For detailed presales guidance and talking points, see [DEMO_GUIDE.md](DEMO_GUIDE.md)
