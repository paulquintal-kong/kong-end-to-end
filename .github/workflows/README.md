# FHIR API Governance & Testing Workflows

This directory contains GitHub Actions workflows for automated governance and testing of the FHIR API.

## Workflows

### 🔍 API Governance and Testing
**File:** `api-governance.yml`

Comprehensive workflow that runs governance checks and API tests.

#### Triggers
- **Manual**: Via workflow_dispatch with environment selection
- **Automatic**: On push/PR to main branch when spec files change

#### Jobs

##### 1. Governance Job
- Lints OpenAPI specification using Inso CLI
- Validates against Spectral rules
- Uploads lint reports as artifacts

##### 2. Test Job
- Starts FHIR server (HAPI) as a service container
- Waits for server to be ready
- Runs Insomnia test collection using Inso CLI
- Generates test reports

##### 3. Summary Job
- Creates workflow summary with results
- Shows pass/fail status for all jobs

## Running Manually

### Via GitHub UI
1. Go to **Actions** tab in your repository
2. Select **FHIR API Governance and Testing**
3. Click **Run workflow**
4. Select environment (local/dev/staging)
5. Click **Run workflow** button

### Via GitHub CLI
```bash
# Run with default environment (local)
gh workflow run api-governance.yml

# Run with specific environment
gh workflow run api-governance.yml -f environment=dev
```

## Running Locally

### Governance Check
```bash
# Install Inso CLI
npm install -g @kong/insomnia-inso

# Run linting
inso lint spec .insomnia/fhir-api-openapi.yaml
```

### API Tests
```bash
# Start FHIR server first
docker-compose up -d

# Run tests
inso run test "FHIR API for Patient, Observation, Encounter, Condition, and Medication (Smile CDR Compatible) 1.0.1-wrk_8482e43ebd4e4c63923f4f78a48863ce.yaml" \
  --env "Base Environment"
```

## Artifacts

The workflow generates and uploads:
- **lint-report**: Contains linting results and spec files
- **test-results**: Contains test execution results

Artifacts are retained for 30 days.

## Requirements

- FHIR server running at `http://localhost:8080/fhir`
- Node.js 20+
- Inso CLI installed

## Customization

### Change FHIR Server
Edit the `services.fhir-server` section in the workflow:
```yaml
services:
  fhir-server:
    image: your-custom-fhir-server:tag
    ports:
      - 8080:8080
```

### Add More Environments
Edit the `inputs.environment.options` section:
```yaml
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
- run: npm install -g @kong/insomnia-inso
```

### Test Collection Not Found
Verify the workspace file name matches exactly:
```bash
ls -la "FHIR API for Patient"*.yaml
```
