# FHIR API Testing Environment

A complete FHIR API development and testing environment with automated linting, testing, and CI/CD.

## Quick Start

```bash
# Start everything (FHIR server + ngrok tunnel)
./start_demo.sh

# Restart everything
./start_demo.sh restart

# Stop everything
./stop_demo.sh
```

That's it! The script will:
- Start Colima (Docker runtime for macOS)
- Launch HAPI FHIR server on `localhost:8080`
- Create ngrok tunnel for remote access
- Update Insomnia workspace with ngrok URL
- Save tunnel URL to `.ngrok-url.txt` for CI/CD

## What's Included

### FHIR Server
- **HAPI FHIR v8.6.0** - Open-source FHIR R4 server
- **H2 Database** - In-memory database (resets on restart)
- **Local Access**: `http://localhost:8080/fhir`
- **Public Access**: via ngrok tunnel (see `.ngrok-url.txt`)

### API Specification & Testing
- **OpenAPI 3.1.0** specification in `.insomnia/fhir-api-openapi.yaml`
- **Insomnia** test collection in `.insomnia/fhir-api-insomnia.yaml` with 3 Patient endpoint tests
- **Spectral** linting with 32 custom FHIR business rules

### CI/CD
- **GitHub Actions** workflow for automatic API governance and testing
- Runs on every push to `main` or when manually triggered
- Tests run against your local server via ngrok tunnel

## File Structure

```
.
├── start_demo.sh                    # Main startup script
├── stop_demo.sh                     # Shutdown script
├── docker-compose.yml               # HAPI FHIR server configuration
├── .insomnia/                       # API specs & workspace
│   ├── fhir-api-openapi.yaml        # OpenAPI 3.1.0 specification
│   └── fhir-api-insomnia.yaml       # Insomnia workspace with tests
├── .spectral.yaml                   # API linting rules
├── .github/workflows/               # CI/CD pipeline
│   └── api-governance.yml
├── .ngrok-url.txt                   # Current ngrok tunnel URL (auto-generated)
└── Demo-Background.md               # Project background
```

## Testing Locally

### Run Tests with Inso CLI

```bash
# Install Inso CLI (if needed)
brew install inso

# Run all Patient tests
inso run collection "FHIR API for Patient, Observation, Encounter, Condition, and Medication (Smile CDR Compatible) 1.0.1" \
  -w ".insomnia/fhir-api-insomnia.yaml" \
  -e "OpenAPI env localhost:8080" \
  -i "fld_455a2d36511e4d16ae4f5ef00cccafc3" \
  --bail
```

### View FHIR Server

```bash
# Metadata endpoint
curl http://localhost:8080/fhir/metadata

# Get Patient by ID
curl http://localhost:8080/fhir/Patient/patient-1013

# Search Patients
curl "http://localhost:8080/fhir/Patient?family=Test"
```

### Useful Commands

```bash
# View server logs
docker-compose logs -f

# Stop everything (ngrok + containers + Colima)
./stop_demo.sh

# Restart server only (keep ngrok running)
docker-compose restart
```

## GitHub Actions Setup

### 1. Set Repository Variables

Go to **Settings** → **Secrets and variables** → **Actions** → **Variables**, add:

| Variable | Value | Description |
|----------|-------|-------------|
| `FHIR_PATIENT_ID` | `patient-1013` | Patient ID for testing |
| `FHIR_BASE_PATH` | `/fhir` | FHIR API base path |
| `FHIR_SCHEME` | `https` | Protocol (https for ngrok) |

**Quick setup with GitHub CLI:**
```bash
gh variable set FHIR_PATIENT_ID --body "patient-1013"
gh variable set FHIR_BASE_PATH --body "/fhir"
gh variable set FHIR_SCHEME --body "https"
```

### 2. Start Local Server & Commit Tunnel URL

```bash
# Start server with ngrok
./start_demo.sh

# Commit the ngrok URL for CI/CD
git add .ngrok-url.txt
git commit -m "Update ngrok tunnel URL"
git push
```

### 3. Workflow Will Run Automatically

The workflow will:
1. ✅ Lint OpenAPI spec with Spectral
2. ✅ Extract ngrok host from `.ngrok-url.txt`
3. ✅ Update CI environment in workspace
4. ✅ Run Insomnia test collection
5. ✅ Display test results

**Manual Trigger:**
- Go to **Actions** → **FHIR API Governance and Testing** → **Run workflow**

## Test Data

A test patient with ID `patient-1013` is required for tests to pass.

### Create Test Patient

```bash
# Using ngrok tunnel (for CI/CD)
NGROK_URL=$(cat .ngrok-url.txt)
curl -X PUT "$NGROK_URL/Patient/patient-1013" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "patient-1013",
    "name": [{"family": "Test", "given": ["Patient"]}],
    "gender": "unknown",
    "birthDate": "2000-01-01"
  }'

# Or using localhost
curl -X PUT "http://localhost:8080/fhir/Patient/patient-1013" \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "id": "patient-1013",
    "name": [{"family": "Test", "given": ["Patient"]}],
    "gender": "unknown",
    "birthDate": "2000-01-01"
  }'
```

**Note:** HAPI FHIR requires client-assigned IDs to contain at least one non-numeric character. IDs like `1013` will be rejected.

## API Linting Rules

The `.spectral.yaml` file contains 32 custom FHIR business validation rules covering:

- **Required Fields**: Patient name, identifier, birthDate
- **HTTP Status Codes**: All endpoints must return 200/201, 400, 404
- **Security**: API Key or OAuth2 required on all endpoints
- **Pagination**: Proper Bundle structure for search results
- **Audit Fields**: meta.lastUpdated, meta.versionId
- **Data Quality**: Gender codes, date formats, identifier systems

### Run Linting Locally

```bash
# Install Spectral VS Code extension or CLI
npm install -g @stoplight/spectral-cli

# Lint the OpenAPI spec
spectral lint .insomnia/fhir-api-openapi.yaml
```

## Troubleshooting

### Tests Failing with 404 Errors

The patient with ID `patient-1013` doesn't exist. Create it using the curl command above.

### Ngrok Tunnel Not Accessible in CI/CD

1. Verify local server is running: `docker-compose ps`
2. Check ngrok tunnel: `curl $(cat .ngrok-url.txt)/metadata`
3. Ensure `.ngrok-url.txt` is committed and pushed to GitHub
4. Remember: ngrok free tier URLs expire after 2 hours and change on restart

### Container Exit 127 or Docker Errors

```bash
# Restart Colima
colima stop
colima start --cpu 2 --memory 4

# Restart containers
./start_demo.sh restart
```

### HAPI FHIR Rejects IDs

Client-assigned IDs must contain at least one non-numeric character. Use `patient-1013` instead of `1013`.

## Environment Configuration

### Local Development
Uses **"OpenAPI env localhost:8080"** environment in Insomnia workspace:
- Automatically updated by `start_demo.sh`
- Points to ngrok tunnel for compatibility with CI/CD
- Values: scheme, host, base_path, id, xApiKey

### CI/CD
Uses **"CI"** environment in Insomnia workspace:
- Automatically updated by GitHub Actions workflow
- Populated from repository variables + ngrok URL
- Isolated from local development environment

## Resources

- **HAPI FHIR**: https://hapifhir.io/
- **FHIR R4 Specification**: https://hl7.org/fhir/R4/
- **Insomnia**: https://insomnia.rest/
- **Spectral**: https://stoplight.io/open-source/spectral
- **Ngrok**: https://ngrok.com/

## License

This is a demo/testing environment. HAPI FHIR is licensed under Apache 2.0.
