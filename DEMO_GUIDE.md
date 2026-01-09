# Kong API Lifecycle Demo - Presales Guide

## 🎯 Overview

This repository demonstrates the complete API lifecycle using Kong Konnect, structured by persona and responsibility. Perfect for technical presales demonstrations showing how different teams collaborate to deliver APIs.

## 👥 Personas & Stages

### Stage 1: Platform Engineer (Infrastructure Foundation)
**Persona**: DevOps/Platform Engineering Team  
**Focus**: Infrastructure provisioning and gateway management  
**Location**: `terraform/stages/1-platform/`

**Key Activities**:
- Provision Kong Gateway control plane
- Set up infrastructure foundation
- Configure base platform settings

**Demo Script**:
```bash
cd terraform/stages/1-platform
terraform init
terraform plan
terraform apply

# Outputs:
# - Control Plane ID
# - Control Plane endpoint
# - Platform configuration
```

---

### Stage 2: Integration Engineer (API Gateway Configuration)
**Persona**: Integration/Backend Engineering Team  
**Focus**: Connecting APIs to Kong Gateway  
**Location**: `terraform/stages/2-integration/`  
**Dependencies**: Stage 1 outputs (control_plane_id)

**Key Activities**:
- Configure gateway services (upstream connections)
- Set up routes and traffic rules
- Define API endpoints
- Test connectivity

**Demo Script**:
```bash
cd terraform/stages/2-integration

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
konnect_token      = "your-token"
control_plane_id   = "from-stage-1-output"
upstream_url       = "https://your-backend-api.com"
EOF

terraform init
terraform plan
terraform apply

# Outputs:
# - Service ID
# - Route ID
# - Public API endpoint
```

**Demo Points**:
- Show upstream service configuration
- Explain routing logic
- Demonstrate traffic flow through gateway
- Test API connectivity

---

### Stage 3: API Developer / Quality Engineer (Spec Development & Testing)
**Persona**: API Developer / QA Engineering Team  
**Focus**: API specification development, linting, and testing  
**Location**: `terraform/stages/3-api-spec-testing/`  
**Dependencies**: Stage 2 outputs

**Key Activities**:
- Develop and maintain OpenAPI specifications
- Validate specs using Insomnia CLI (inso)
- Enforce linting rules with Spectral
- Create and run API test collections
- Integrate validation into CI/CD pipelines

**Demo Script**:
```bash
cd terraform/stages/3-api-spec-testing
./demo.sh

# What the script validates:
# - OpenAPI 3.1 syntax correctness
# - FHIR-specific linting rules
# - Healthcare domain compliance
# - Test collection structure
# - CI/CD integration
```

**Demo Points**:
- Show OpenAPI spec in `.insomnia/fhir-api-openapi.yaml`
- Run `inso lint spec` to validate syntax
- Demonstrate custom Spectral rules in `.spectral.yaml`:
  - FHIR resource structure requirements
  - Patient identifier validation
  - Healthcare data compliance rules
- Show Insomnia test collection (`.insomnia/fhir-api-insomnia.yaml`):
  - 50+ test cases covering all FHIR resources
  - CRUD operation tests
  - Search functionality tests
  - Error handling validation
- Explain CI/CD integration:
  - `.github/workflows/api-governance.yml` runs on every push
  - Automatic spec linting
  - Test validation before merge
  - Quality gates prevent bad specs from deploying

**Value Proposition**:
- **Shift-Left Quality**: Catch spec issues before deployment
- **Contract-First Development**: API specs validated before implementation
- **Automated Governance**: No manual spec reviews needed
- **Developer Productivity**: Immediate feedback on spec quality
- **Compliance Assurance**: Healthcare standards enforced automatically

**Common Questions**:
- Q: "How do developers create specs?"
  - A: Use Insomnia desktop app, export to `.insomnia/` directory
- Q: "What if specs don't pass validation?"
  - A: GitHub Actions blocks merge, developer gets immediate feedback
- Q: "Can we customize linting rules?"
  - A: Yes, edit `.spectral.yaml` for domain-specific requirements
- Q: "How are tests executed?"
  - A: Locally via `inso run test`, or in CI/CD via GitHub Actions

---

### Stage 4: API Owner (Productization & Governance)
**Persona**: API Product Manager  
**Focus**: API catalog, governance, and policies  
**Location**: `terraform/stages/4-api-product/`  
**Dependencies**: Stage 1 (control_plane_id) + Stage 2 (service_id)

**Key Activities**:
- Publish APIs to internal catalog
- Manage OpenAPI specifications
- Implement governance policies (rate limiting, security)
- Link APIs to implementations
- Set SLAs and quality standards

**Demo Script**:
```bash
cd terraform/stages/4-api-product

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
konnect_token        = "your-token"
control_plane_id     = "from-stage-1"
service_id           = "from-stage-2"
openapi_spec_path    = "../../../.insomnia/fhir-api-openapi.yaml"
rate_limit_per_minute = 5
EOF

terraform init
terraform plan
terraform apply

# Outputs:
# - Catalog Service ID
# - API ID
# - API Specification ID
# - Rate limiting plugin ID
```

**Demo Points**:
- Show API in Kong Catalog
- View OpenAPI specification in UI
- Explain rate limiting policy (5 req/min)
- Demonstrate governance controls
- Show API-to-service linkage

---

### Stage 5: API Owner (Developer Portal Publishing)
**Persona**: Developer Experience Lead  
**Focus**: External developer onboarding and API discovery  
**Location**: `terraform/stages/5-developer-portal/`  
**Dependencies**: Stage 4 (catalog_api_id)

**Key Activities**:
- Create developer portal
- Publish APIs for external consumption
- Configure developer onboarding workflow
- Manage API visibility and access

**Demo Script**:
```bash
cd terraform/stages/5-developer-portal

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
konnect_token              = "your-token"
catalog_api_id             = "from-stage-3"
portal_name                = "Patient Records API"
enable_auth                = false  # true for private portal
auto_approve_developers    = false  # true for self-service
EOF

terraform init
terraform plan
terraform apply

# Outputs:
# - Portal URL
# - Portal configuration
# - Developer onboarding instructions
```

**Demo Points**:
- Visit the developer portal URL
- Browse API catalog
- Show API documentation (OpenAPI spec)
- Explain developer registration flow
- Demo application creation

---

### Stage 6: 3rd Party Developer (API Consumption) - MANUAL DEMO
**Persona**: External Developer  
**Focus**: Discovering and consuming APIs  
**Location**: Developer Portal (web UI)

**Key Activities**:
1. **Discover APIs**: Browse portal at the URL from Stage 4
2. **Register**: Create developer account (if auth enabled)
3. **Create Application**: Register an app to consume APIs
4. **Get Credentials**: Request API keys or OAuth credentials
5. **Test API**: Make API calls using provided credentials
6. **Monitor Usage**: View analytics and quota consumption

**Demo Script**:
```bash
# 1. Open portal URL from Stage 5 output
open https://[portal-domain].au.kongportals.com

# 2. In Portal UI:
# - Browse "APIs" section
# - View "Patient Records API"
# - Read documentation
# - Try "Test" feature (interactive API explorer)

# 3. If auth enabled:
# - Click "Sign Up"
# - Register developer account
# - Wait for approval (or instant if auto_approve=true)

# 4. Create Application:
# - Navigate to "My Apps"
# - Click "New Application"
# - Select "Patient Records API"
# - Request credentials

# 5. Test with credentials:
curl -H "apikey: YOUR-API-KEY" \
  https://[control-plane-id].au.cp0.konghq.com/api/patients

# 6. Observe rate limiting (after 5 requests):
# HTTP 429 Too Many Requests
```

**Demo Points**:
- Self-service API discovery
- Clear documentation
- Easy credential management
- Rate limiting in action
- Developer analytics

---

## 🎬 Demo Flow

### Quick Demo (15 minutes)
1. **Stage 1** (2 min): Show existing control plane
2. **Stage 2** (3 min): Explain service/route configuration
3. **Stage 3** (2 min): Quick spec validation and CI/CD overview
4. **Stage 4** (4 min): Focus on catalog, spec, rate limiting
5. **Stage 5** (2 min): Quick portal tour
6. **Stage 6** (2 min): Live API testing with rate limit demo

### Full Demo (30-45 minutes)
Run each stage sequentially with detailed explanations:
- Stage 1: Infrastructure foundation (5 min)
- Stage 2: API integration (8 min)
- Stage 3: Spec development & testing (8 min)
- Stage 4: Governance & productization (10 min)
- Stage 5: Portal publishing (5 min)
- Stage 6: Developer experience walkthrough (8 min)

### API Governance Focus Demo (20 minutes)
Perfect for quality/compliance audiences:
- Stage 1: Quick setup (2 min)
- Stage 2: Basic integration (3 min)
- **Stage 3: Deep dive on spec linting and testing (10 min)**
  - Show Insomnia spec development
  - Run live linting with custom rules
  - Demonstrate test execution
  - Show GitHub Actions integration
- Stage 4: Policy enforcement (5 min)

---

## 📊 Demo Talking Points by Persona

### Platform Engineer
- **Challenge**: "How do we standardize API infrastructure across teams?"
- **Solution**: Central control plane, infrastructure as code
- **Value**: Consistency, auditability, multi-environment support

### Integration Engineer
- **Challenge**: "How do we expose backend services securely?"
- **Solution**: Gateway service abstraction, routing, transformation
- **Value**: Decoupling, traffic management, protocol translation

### API Developer / QA Engineer
- **Challenge**: "How do we ensure API quality before deployment?"
- **Solution**: Automated spec linting, custom Spectral rules, test collections, CI/CD integration
- **Value**: Shift-left quality, contract-first development, automated compliance, faster feedback
- **Key Points**:
  - Specs validated before code is written
  - Custom rules enforce organizational standards (e.g., FHIR compliance)
  - Tests run automatically in CI/CD pipeline
  - Quality gates prevent bad specs from reaching production
  - Developers get immediate feedback on spec issues

### API Product Manager
- **Challenge**: "How do we govern APIs and prevent abuse?"
- **Solution**: Catalog, specifications, policy enforcement
- **Value**: Discoverability, compliance, quality standards, SLA enforcement

### Developer Experience Lead
- **Challenge**: "How do we onboard external developers quickly?"
- **Solution**: Self-service portal, auto-generated docs, credential management
- **Value**: Faster time-to-first-API-call, reduced support burden, developer satisfaction

### 3rd Party Developer
- **Challenge**: "How do I find and use your APIs?"
- **Solution**: Public portal, interactive docs, instant credentials
- **Value**: Self-service, clear documentation, easy testing

---

## 🔄 Demo Variations

### Variation 1: API Governance & Quality Focus
**Scenario**: Organization needs to enforce API standards and compliance

**Key Stages**: 3 + 4
- Stage 3: Show how specs are validated automatically
  - Custom Spectral rules for FHIR/healthcare compliance
  - Linting in CI/CD blocks bad specs
  - Test collections ensure functionality
- Stage 4: Show policy enforcement (rate limiting, auth)

**Talking Points**:
- "Every API spec is validated against 20+ custom rules"
- "Developers get instant feedback when specs don't comply"
- "No manual reviews needed - automation catches 95% of issues"
- "Healthcare regulations enforced at the spec level"

### Variation 2: Public vs Private Portal
**Scenario**: Different API exposure models

**Public Portal** (terraform.tfvars):
```hcl
enable_auth             = false
auto_approve_developers = false  # N/A when auth disabled
```
- Anyone can browse and read docs
- Must register to get credentials

**Private Portal** (terraform.tfvars):
```hcl
enable_auth             = true
auto_approve_developers = false
```
- Login required to view portal
- Admin approves each developer
- Best for partner/B2B APIs

---

### Variation 2: Self-Service vs Controlled Onboarding
**Scenario**: Developer approval workflow

**Self-Service** (terraform.tfvars):
```hcl
enable_auth             = true
auto_approve_developers = true
```
- Instant developer access
- Fast onboarding
- Higher risk tolerance

**Controlled** (terraform.tfvars):
```hcl
enable_auth             = true
auto_approve_developers = false
```
- Manual approval required
- Vetting process
- Higher security/compliance needs

---

### Variation 3: Additional Governance Policies
**Scenario**: Enhanced security and compliance

Edit `stages/3-api-product/plugins.tf` and uncomment:

**CORS** (for browser-based apps):
```hcl
resource "konnect_gateway_plugin_cors" "api_cors" {
  enabled          = true
  control_plane_id = var.control_plane_id
  service = { id = var.service_id }
  
  config = {
    origins     = ["https://app.example.com"]
    methods     = ["GET", "POST"]
    credentials = true
  }
}
```

**API Key Authentication**:
```hcl
resource "konnect_gateway_plugin_key_auth" "api_key_auth" {
  enabled          = true
  control_plane_id = var.control_plane_id
  service = { id = var.service_id }
  
  config = {
    key_names = ["apikey"]
  }
}
```

**Request Transformation**:
```hcl
resource "konnect_gateway_plugin_request_transformer" "add_headers" {
  config = {
    add = {
      headers = ["X-API-Version:1.0"]
    }
  }
}
```

---

## 🎓 Key Selling Points

### For Platform Teams
✅ **Infrastructure as Code**: Everything in version control  
✅ **Multi-environment**: Promote configs from dev → prod  
✅ **Standardization**: Consistent platform across org  
✅ **Auditability**: Track all changes via Git  

### For API Teams
✅ **Faster Time-to-Market**: Automated publishing pipeline  
✅ **Built-in Governance**: Rate limiting, auth, CORS out of the box  
✅ **Self-Service Portal**: Reduces support burden  
✅ **Analytics**: Built-in API usage monitoring  

### For Developers
✅ **Discovery**: Find APIs easily in catalog  
✅ **Documentation**: Always up-to-date OpenAPI specs  
✅ **Testing**: Interactive API explorer  
✅ **Self-Service**: Get credentials instantly  

---

## 📁 Repository Structure

```
terraform/
├── stages/
│   ├── 1-platform/          # Platform Engineer
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── control_plane.tf
│   │   └── outputs.tf
│   │
│   ├── 2-integration/       # Integration Engineer
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── gateway_service.tf
│   │   └── outputs.tf
│   │
│   ├── 3-api-product/       # API Owner (Productization)
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── catalog.tf
│   │   ├── plugins.tf
│   │   └── outputs.tf
│   │
│   └── 4-developer-portal/  # API Owner (Publishing)
│       ├── provider.tf
│       ├── variables.tf
│       ├── portal.tf
│       └── outputs.tf
│
├── provider.tf              # [Legacy - kept for reference]
├── *.tf                     # [Legacy - kept for reference]
└── portal/                  # Portal content export

.insomnia/
└── fhir-api-openapi.yaml    # OpenAPI specification
```

---

## 🚀 Quick Start for Demo

### Prerequisites
- Kong Konnect account (AU region)
- Personal Access Token
- Terraform >= 1.0
- AWS credentials (for state backend)

### Run Complete Lifecycle Demo

```bash
# Stage 1: Platform Engineer
cd terraform/stages/1-platform
echo 'konnect_token = "YOUR_TOKEN"' > terraform.tfvars
terraform init && terraform apply -auto-approve
export CONTROL_PLANE_ID=$(terraform output -raw control_plane_id)

# Stage 2: Integration Engineer
cd ../2-integration
cat > terraform.tfvars <<EOF
konnect_token    = "YOUR_TOKEN"
control_plane_id = "$CONTROL_PLANE_ID"
upstream_url     = "https://your-api.com"
EOF
terraform init && terraform apply -auto-approve
export SERVICE_ID=$(terraform output -raw service_id)

# Stage 3: API Owner (Productization)
cd ../3-api-product
cat > terraform.tfvars <<EOF
konnect_token    = "YOUR_TOKEN"
control_plane_id = "$CONTROL_PLANE_ID"
service_id       = "$SERVICE_ID"
EOF
terraform init && terraform apply -auto-approve
export CATALOG_API_ID=$(terraform output -raw catalog_api_id)

# Stage 4: API Owner (Portal)
cd ../4-developer-portal
cat > terraform.tfvars <<EOF
konnect_token  = "YOUR_TOKEN"
catalog_api_id = "$CATALOG_API_ID"
enable_auth    = false
EOF
terraform init && terraform apply -auto-approve

# Open the portal!
open $(terraform output -raw portal_url)
```

---

## 💡 Pro Tips for Demos

1. **Pre-provision Stage 1**: Save time by having control plane ready
2. **Use variables**: Make it easy to switch between scenarios
3. **Show the UI**: Toggle between Terraform and Konnect UI to show both
4. **Rate limit demo**: Make 6+ API calls to trigger 429 error
5. **Highlight IaC**: Show Git history of infrastructure changes
6. **Multi-environment**: Show how same code promotes dev → prod
7. **Analytics**: Log into Konnect to show API usage dashboards

---

## 🎯 Objection Handling

**"We already have an API gateway"**  
→ Show catalog, developer portal, and multi-environment management

**"Too complex to set up"**  
→ Run full lifecycle demo in < 10 minutes

**"How do we govern APIs across teams?"**  
→ Show catalog, specifications, and policy enforcement

**"Developer onboarding is slow"**  
→ Show self-service portal with instant credentials

**"How do we prevent API abuse?"**  
→ Demo rate limiting in real-time (trigger 429 error)

---

## 📚 Additional Resources

- [Kong Konnect Documentation](https://docs.konghq.com/konnect/)
- [Terraform Provider Docs](https://registry.terraform.io/providers/Kong/konnect/latest/docs)
- [FHIR R4 Specification](https://hl7.org/fhir/R4/)

---

**Ready to demo the future of API management!** 🚀
