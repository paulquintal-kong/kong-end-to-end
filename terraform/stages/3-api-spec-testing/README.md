# Stage 3: API Spec Development & Testing

**Persona**: API Developer / Quality Engineer  
**Duration**: 5-10 minutes  
**Prerequisites**: Stage 2 (Integration) completed

---

## Overview

This stage demonstrates the **API-first development workflow** using Insomnia for spec creation, testing, and validation. It shows how API contracts are developed, validated against governance rules, and automatically tested in CI/CD pipelines.

### What This Stage Demonstrates

- **OpenAPI Specification Development**: Creating and maintaining API contracts
- **Linting & Validation**: Automated spec validation using Spectral rules
- **Test Collection Creation**: Building comprehensive API tests in Insomnia
- **CI/CD Integration**: Automated validation on every code change

---

## What Gets Validated

After running this stage, you'll have validated:

| Validation | Tool | Purpose |
|------------|------|---------|
| **OpenAPI Syntax** | Inso CLI | Ensures spec is valid OpenAPI 3.1 |
| **FHIR Compliance** | Spectral | Enforces healthcare API standards |
| **Business Rules** | Custom Spectral Rules | Validates domain-specific requirements |
| **API Functionality** | Insomnia Tests | Verifies endpoints work as expected |

---

## Run the Stage

```bash
cd terraform/stages/2.5-api-spec-testing
./demo.sh
```

### What the Script Does

1. **Validates OpenAPI Spec**: Runs `inso lint spec` against the FHIR API specification
2. **Applies Custom Rules**: Validates using `.spectral.yaml` healthcare-specific rules
3. **Shows Test Collection**: Displays available Insomnia test suites
4. **Demonstrates CI/CD**: Shows GitHub Actions integration for automated validation

---

## Expected Output

```
═══════════════════════════════════════════════════════════════
   Stage 3: API Spec Development & Testing
   Persona: API Developer / Quality Engineer
═══════════════════════════════════════════════════════════════

✓ Repository root: /path/to/kong-end-to-end

━━━ Step 1: Validate OpenAPI Specification ━━━

📄 OpenAPI Spec: .insomnia/fhir-api-openapi.yaml

Running specification validation...

✓ OpenAPI specification passed all linting rules

━━━ Step 2: Validate Against Custom Spectral Rules ━━━

📋 Custom Rules: .spectral.yaml

Custom rules enforce:
  • FHIR-specific resource patterns
  • Patient identifier requirements
  • Healthcare data compliance
  • API documentation standards

✓ All custom rules passed

━━━ Step 3: Run Test Collection ━━━

🧪 Test Collection: .insomnia/fhir-api-insomnia.yaml

This collection includes tests for:
  • Patient resource CRUD operations
  • Observation resource management
  • Encounter and Condition resources
  • Medication records
  • Search functionality
  • Error handling

━━━ Step 4: CI/CD Integration ━━━

GitHub Actions workflows configured:

  📋 api-governance.yml
     • Lints OpenAPI spec on every push
     • Validates against Spectral rules
     • Runs automatically on spec changes

✓ API Governance workflow configured

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Stage 3 Complete: API Spec Development & Testing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Validation Steps

### 1. Verify OpenAPI Spec Linting

```bash
# From repo root
inso lint spec .insomnia/fhir-api-openapi.yaml
```

**Expected Result**: ✅ No errors or warnings

### 2. Check Custom Spectral Rules

```bash
# Install Spectral if not present
npm install -g @stoplight/spectral-cli

# Run validation
spectral lint .insomnia/fhir-api-openapi.yaml
```

**Expected Result**: ✅ All FHIR-specific rules pass

### 3. Review Test Collection

```bash
# List all test suites
inso run test .insomnia/fhir-api-insomnia.yaml --reporter spec
```

**Expected Result**: Test collection structure displayed

### 4. Verify CI/CD Workflow

```bash
# Check workflow file exists
cat .github/workflows/api-governance.yml
```

**Expected Result**: Workflow configured with lint and test jobs

---

## Key Files

### OpenAPI Specification
**Location**: `.insomnia/fhir-api-openapi.yaml`

Contains the complete FHIR R4 API contract with:
- Patient resource endpoints
- Observation, Encounter, Condition endpoints
- Medication management
- Search parameters
- Request/response schemas

### Insomnia Test Collection
**Location**: `.insomnia/fhir-api-insomnia.yaml`

Includes comprehensive tests for:
- All CRUD operations
- Search functionality
- Error handling (404, 400, 500)
- Response validation
- Performance checks

### Custom Linting Rules
**Location**: `.spectral.yaml`

Enforces:
- FHIR resource structure
- Patient identifier requirements
- Metadata compliance
- Healthcare domain rules

### CI/CD Workflow
**Location**: `.github/workflows/api-governance.yml`

Automated pipeline that:
- Triggers on spec file changes
- Runs OpenAPI linting
- Validates Spectral rules
- Exports validated spec
- Reports results

---

## Workflow Integration

### Development Workflow

```
┌──────────────┐
│  Developer   │
│  modifies    │
│  API spec    │
│  in Insomnia │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Export to   │
│  .insomnia/  │
│  directory   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Run local   │
│  validation  │
│  ./demo.sh   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Commit &    │
│  Push to     │
│  GitHub      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  GitHub      │
│  Actions     │
│  validates   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Merge if    │
│  passing     │
└──────────────┘
```

### CI/CD Pipeline

The `api-governance.yml` workflow runs on:
- **Push to main**: Validates all changes
- **Pull requests**: Blocks merge if validation fails
- **Manual trigger**: For ad-hoc testing

---

## Customization

### Adding Custom Spectral Rules

Edit `.spectral.yaml`:

```yaml
rules:
  my-custom-rule:
    description: Custom validation rule
    severity: error
    given: $.paths..responses..content.application/fhir+json.schema
    then:
      field: properties.myField
      function: truthy
    message: Custom validation message
```

### Adding Test Cases

In Insomnia desktop app:
1. Open the FHIR API collection
2. Add new requests
3. Add test scripts in the "Tests" tab
4. Export to `.insomnia/fhir-api-insomnia.yaml`

Example test script:
```javascript
const statusCode = insomnia.response.code;
const jsonBody = insomnia.response.json();

// Test: Verify status code
expect(statusCode).to.equal(200);

// Test: Validate response structure
expect(jsonBody).to.have.property('resourceType');
expect(jsonBody.resourceType).to.equal('Patient');
```

---

## Troubleshooting

### Issue: Inso CLI not found

```bash
npm install -g @insomnia/inso@latest
```

### Issue: Spectral not installed

```bash
npm install -g @stoplight/spectral-cli
```

### Issue: OpenAPI spec has errors

1. Open Insomnia desktop app
2. Import `.insomnia/fhir-api-openapi.yaml`
3. Fix errors shown in the editor
4. Re-export the spec
5. Re-run validation

### Issue: Tests failing

1. Check if backend API is running
2. Verify Stage 2 (Integration) is complete
3. Check environment variables in test collection
4. Review test output for specific failures

---

## Next Steps

Once validation passes:

```bash
cd ../4-api-product
./demo.sh
```

This will:
- Publish the validated API to the catalog
- Add governance policies (rate limiting)
- Make the API discoverable

---

## Resources

- [Insomnia CLI Documentation](https://docs.insomnia.rest/insomnia/inso-cli)
- [Spectral Rulesets](https://meta.stoplight.io/docs/spectral/README.md)
- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [FHIR R4 Documentation](https://hl7.org/fhir/R4/)
- [GitHub Actions Workflows](https://docs.github.com/en/actions)
