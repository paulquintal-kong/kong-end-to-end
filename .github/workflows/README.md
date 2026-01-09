# API Governance & Testing Workflows

This directory contains GitHub Actions workflows for **automated API quality gates**, ensuring all OpenAPI specifications and API implementations meet organizational standards before deployment.

---

## 📋 Workflows Overview

### 🔍 API Governance and Testing
**File:** [`api-governance.yml`](api-governance.yml)

**Purpose**: Comprehensive API quality validation pipeline that enforces:
- OpenAPI specification correctness
- Custom linting rules (FHIR compliance, healthcare standards)
- Automated API testing
- Quality gates that block merges on failure

**Integration**: Part of **Stage 3** (API Spec Development & Testing) in the demo journey

---

## 🚀 Workflow Details

### Triggers

| Trigger | Condition | Use Case |
|---------|-----------|----------|
| **Push to main** | `.insomnia/**` or `.spectral.yaml` changes | Automatic validation on every spec update |
| **Pull Request** | Same file changes | Pre-merge quality gates |
| **Manual Dispatch** | Via GitHub UI or CLI | Ad-hoc testing against different environments |

### Jobs

#### 1️⃣ Governance Job
**Purpose**: Validate API specifications against organizational standards

**Steps**:
1. Checkout code
2. Cache Insomnia CLI for faster runs
3. Install Node.js and Inso CLI
4. **Lint OpenAPI spec** using Inso CLI
   - Validates OpenAPI 3.1 syntax
   - Checks for required fields
   - Ensures spec completeness
5. **Export specification** for downstream use
6. **Upload artifacts**: Spec file and lint reports

**Key Validations**:
- ✅ OpenAPI 3.1 schema compliance
- ✅ All endpoints documented
- ✅ Request/response schemas defined
- ✅ Security schemes configured

**Outputs**:
- `fhir-api-spec` artifact (validated spec file)
- `lint-report` artifact (detailed validation results)

---

#### 2️⃣ Test Job (Future Enhancement)
**Purpose**: Execute Insomnia test collection against API endpoints

**Planned Steps**:
1. Start FHIR server (HAPI) as service container
2. Wait for server readiness
3. Run Insomnia test collection using Inso CLI
4. Generate test reports
5. Upload test results

**Test Coverage** (when enabled):
- Patient resource CRUD operations
- Observation, Encounter, Condition resources
- Medication management
- Search functionality
- Error handling (404, 400, 500 responses)
- Performance validation

---

#### 3️⃣ Summary Job
**Purpose**: Aggregate results and create workflow summary

**Displays**:
- ✅/❌ Governance check status
- ✅/❌ Test execution status  
- 📊 Summary metrics
- 🔗 Links to artifacts

---

## 🎯 Quality Gates

This workflow acts as a **quality gate** in your CI/CD pipeline:

```
Developer Push
      │
      ▼
┌─────────────┐
│   Linting   │  ← Blocks if OpenAPI spec invalid
└──────┬──────┘
       │ PASS
       ▼
┌─────────────┐
│  Spectral   │  ← Blocks if custom rules fail
│   Rules     │    (FHIR compliance, etc.)
└──────┬──────┘
       │ PASS
       ▼
┌─────────────┐
│   Tests     │  ← Blocks if API tests fail
└──────┬──────┘
       │ PASS
       ▼
   Merge OK
```

**Failure Handling**:
- ❌ Lint failures → PR cannot merge
- ❌ Rule violations → PR cannot merge  
- ❌ Test failures → PR cannot merge
- ✅ All pass → PR approved for merge

---

## 🔧 Running Workflows

### Via GitHub UI (Recommended for Demo)

1. Navigate to **Actions** tab
2. Select **FHIR API Governance and Testing**
3. Click **Run workflow**
4. Select environment:
   - `local`: For local development
   - `dev`: Development environment
   - `staging`: Pre-production
5. Click **Run workflow** button

**Demo Tip**: Run this during Stage 3 to show live validation!

### Via GitHub CLI

```bash
# Run with default environment (local)
gh workflow run api-governance.yml

# Run with specific environment
gh workflow run api-governance.yml -f environment=staging

# View run status
gh run list --workflow=api-governance.yml
```

### Via Git Push (Automatic)

```bash
# Make changes to spec
vim .insomnia/fhir-api-openapi.yaml

# Commit and push
git add .insomnia/
git commit -m "Update Patient endpoint schema"
git push origin feature/update-spec

# Workflow runs automatically on PR creation
```

---

## 💻 Running Locally

### Governance Check

```bash
# Install Inso CLI globally
npm install -g @insomnia/inso

# Lint the specification
inso lint spec .insomnia/fhir-api-openapi.yaml

# Expected output:
# ✅ Specification: fhir-api-openapi.yaml is valid
```

### Spectral Validation (Custom Rules)

```bash
# Install Spectral CLI
npm install -g @stoplight/spectral-cli

# Run custom linting rules
spectral lint .insomnia/fhir-api-openapi.yaml

# Expected output:
# ✅ No errors or warnings
```

### API Tests (Local)

```bash
# Start FHIR server first
docker-compose up -d

# Wait for server readiness
sleep 10

# Run test collection
inso run test .insomnia/fhir-api-insomnia.yaml \\
  --env "Base Environment" \\
  --reporter spec

# Stop server
docker-compose down
```

---

## 📦 Artifacts

The workflow generates downloadable artifacts:

| Artifact | Contents | Retention | Use Case |
|----------|----------|-----------|----------|
| **fhir-api-spec** | Validated OpenAPI spec (YAML) | 30 days | Deploy to production, share with partners |
| **lint-report** | Linting results, spec files | 30 days | Troubleshooting validation failures |
| **test-results** | Test execution reports | 30 days | Quality metrics, coverage analysis |

**Accessing Artifacts**:
1. Go to workflow run page
2. Scroll to **Artifacts** section
3. Download ZIP file

---

## 🛠️ Customization

### Adding Custom Spectral Rules

Edit [`.spectral.yaml`](../../.spectral.yaml):

```yaml
rules:
  my-custom-rule:
    description: Enforce organization-specific standards
    severity: error
    given: $.paths..responses
    then:
      field: description
      function: truthy
    message: All responses must have descriptions
```

### Changing FHIR Server

Edit `api-governance.yml`:

```yaml
```yaml
services:
  fhir-server:
    image: hapiproject/hapi:latest  # or your custom image
    ports:
      - 8080:8080
    env:
      HAPI_FHIR_VERSION: R4
```

### Adding More Test Environments

Edit workflow inputs:

```yaml
inputs:
  environment:
    type: choice
    options:
      - local
      - dev
      - staging
      - production  # Add new environment
```

### Customizing Test Reports

Edit test job to use different reporters:

```bash
# JUnit format (for CI integration)
inso run test --reporter junit > test-results.xml

# Spec format (detailed)
inso run test --reporter spec

# JSON format (programmatic parsing)
inso run test --reporter json > test-results.json
```

---

## 🔗 Integration with Demo Journey

This workflow is integral to **Stage 2.5: API Spec Development & Testing**:

### Demo Flow Integration

```
Stage 2: Integration
      │
      ▼
┌──────────────────┐
│  Developer edits │
│   OpenAPI spec   │
│   in Insomnia    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Export spec    │
│   to .insomnia/  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Run Stage 3     │  ← ./demo.sh validates locally
│   ./demo.sh      │
└────────┬─────────┘
         │ PASS
         ▼
┌──────────────────┐
│ Commit & push    │
│   to GitHub      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  GitHub Actions  │  ← api-governance.yml runs
│  validates spec  │
└────────┬─────────┘
         │ PASS
         ▼
┌──────────────────┐
│  PR approved &   │
│  ready to merge  │
└────────┬─────────┘
         │
         ▼
   Stage 4: API Product
```

### Demo Talking Points

**When showing this workflow**:
1. "This runs automatically on every commit touching API specs"
2. "It validates against 20+ custom rules for FHIR compliance"
3. "Failed validation blocks PR merge - no bad specs reach production"
4. "Developers get immediate feedback in GitHub UI"
5. "Average validation time: 30-45 seconds"

**Live Demo Steps**:
1. Make a small change to `.insomnia/fhir-api-openapi.yaml`
2. Commit and push to feature branch
3. Show workflow running in GitHub Actions tab
4. Show validation results in PR checks
5. Demonstrate failure scenario (optional):
   - Remove required field from spec
   - Push again
   - Show workflow failure and error messages

---

## 📊 Metrics & Monitoring

### Workflow Success Rates

Track quality metrics over time:
- **Lint Pass Rate**: % of commits passing linting
- **Rule Compliance**: % passing custom Spectral rules  
- **Test Pass Rate**: % of test executions successful
- **Mean Time to Validate**: Average workflow execution time

### Accessing Metrics

```bash
# List recent workflow runs
gh run list --workflow=api-governance.yml --limit 20

# Get specific run details
gh run view <run-id>

# Download artifacts programmatically
gh run download <run-id>
```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: Inso CLI not found
```bash
# Solution: Install globally
npm install -g @insomnia/inso@latest
```

#### Issue: Spectral validation failing
```bash
# Check which rules are failing
spectral lint .insomnia/fhir-api-openapi.yaml --format stylish

# Disable specific rules (if needed)
# Edit .spectral.yaml:
rules:
  rule-name: off
```

#### Issue: Test collection not found
```bash
# Verify file exists
ls -la .insomnia/

# Check file name matches workflow
cat .github/workflows/api-governance.yml | grep "run test"
```

#### Issue: Workflow not triggering
```bash
# Verify triggers in workflow file
cat .github/workflows/api-governance.yml | grep -A 10 "^on:"

# Check file paths match
git diff --name-only main...HEAD
```

### Debug Mode

Enable debug logging:

```yaml
# In api-governance.yml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

---

## 📚 Resources

- [Insomnia CLI Documentation](https://docs.insomnia.rest/insomnia/inso-cli)
- [Spectral Linting Rules](https://meta.stoplight.io/docs/spectral/README.md)
- [GitHub Actions Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0)
- [FHIR R4 Documentation](https://hl7.org/fhir/R4/)

---

## 🎯 Best Practices

1. **Keep specs in version control**: Always commit `.insomnia/` files
2. **Run locally first**: Validate with `./demo.sh` before pushing
3. **Meaningful commit messages**: Help track which changes broke validation
4. **Monitor workflow runs**: Set up notifications for failures
5. **Regular rule updates**: Review and update `.spectral.yaml` quarterly
6. **Artifact cleanup**: Download important artifacts before 30-day expiry

---

## 🚀 Next Steps

After validating your API spec:

1. **Proceed to Stage 4**: Publish API to catalog
   ```bash
   cd terraform/stages/4-api-product
   ./demo.sh
   ```

2. **Create production workflow**: Extend to deploy validated specs
3. **Add security scanning**: Integrate OWASP ZAP or similar
4. **Enable notifications**: Set up Slack/email alerts for failures

---

**Related Documentation**:
- [Stage 3 README](../../terraform/stages/3-api-spec-testing/README.md)
- [Main Demo Guide](../../DEMO_GUIDE.md)
- [Repository README](../../README.md)
inputs:
  environment:
    type: choice
    options:
      - local
      - dev
      - staging
      - production
```

### Change Test Reporter
Available reporters: `cli`, `json`, `junit`, `dot`, `spec`

```bash
inso run test ... --reporter junit --reporter-output test-results.xml
```

## Status Badges

Add to your README.md:

```markdown
![API Governance](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/api-governance.yml/badge.svg)
```

## Troubleshooting

### Tests Fail - Server Not Ready
Increase the timeout in the "Wait for FHIR server" step:
```yaml
timeout 300 bash -c '...'  # 5 minutes
```

### Inso Not Found
Ensure the installation step runs successfully:
```yaml
- run: npm install -g insomnia-inso
```

### Test Collection Not Found
Verify the workspace file name matches exactly:
```bash
ls -la "FHIR API for Patient"*.yaml
```
