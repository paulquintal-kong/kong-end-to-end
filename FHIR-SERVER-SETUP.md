# Smile CDR (HAPI FHIR) Docker Setup

This setup uses HAPI FHIR, an open-source FHIR server that is compatible with Smile CDR's API structure.

## Prerequisites

- Docker installed on your Mac
- Docker Compose installed

## Quick Start

### 1. Start the FHIR Server

```bash
docker-compose up -d
```

This will:
- Pull the HAPI FHIR server image
- Start the server on port 8080
- Use an in-memory H2 database (demo mode)

### 2. Verify the Server is Running

Wait about 60 seconds for the server to fully start, then check:

```bash
curl http://localhost:8080/fhir/metadata
```

Or open in your browser:
- **FHIR Base URL**: http://localhost:8080/fhir
- **Web UI**: http://localhost:8080/ (includes a web-based FHIR client)

### 3. Test with Sample FHIR Resources

#### Create a Patient

```bash
curl -X POST http://localhost:8080/fhir/Patient \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Patient",
    "name": [{
      "use": "official",
      "family": "Smith",
      "given": ["John"]
    }],
    "gender": "male",
    "birthDate": "1990-01-01"
  }'
```

#### Search for Patients

```bash
curl http://localhost:8080/fhir/Patient
```

#### Create an Observation

```bash
curl -X POST http://localhost:8080/fhir/Observation \
  -H "Content-Type: application/fhir+json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "code": {
      "coding": [{
        "system": "http://loinc.org",
        "code": "85354-9",
        "display": "Blood pressure panel"
      }]
    },
    "valueQuantity": {
      "value": 120,
      "unit": "mmHg",
      "system": "http://unitsofmeasure.org"
    }
  }'
```

## Server Configuration

- **FHIR Version**: R4
- **Base URL**: http://localhost:8080/fhir
- **Database**: H2 in-memory (data is lost when container stops)
- **CORS**: Enabled for all origins
- **Validation**: Enabled

## Useful Commands

### View Logs
```bash
docker-compose logs -f fhir-server
```

### Stop the Server
```bash
docker-compose down
```

### Stop and Remove Data
```bash
docker-compose down -v
```

### Restart the Server
```bash
docker-compose restart
```

### Check Server Status
```bash
docker-compose ps
```

## Connecting to Kong Gateway

Update your Kong service upstream to point to:
- **URL**: http://fhir-server:8080/fhir (from within Docker network)
- **URL**: http://localhost:8080/fhir (from host machine)

If Kong is running in Docker, make sure to add it to the same network:

```yaml
# Add to your Kong docker-compose
networks:
  - fhir-network

networks:
  fhir-network:
    external: true
```

## For Production Use

For a production setup, you would want to:

1. Use a persistent database (PostgreSQL)
2. Configure proper authentication
3. Use the commercial Smile CDR product
4. Set up TLS/SSL
5. Configure proper backups

## Troubleshooting

### Port Already in Use
If port 8080 is already in use, edit `docker-compose.yml` and change:
```yaml
ports:
  - "8081:8080"  # Use port 8081 instead
```

### Container Won't Start
Check the logs:
```bash
docker-compose logs fhir-server
```

### Server Taking Too Long to Start
The server needs about 60 seconds to initialize. Check health status:
```bash
docker-compose ps
```

## API Documentation

- **FHIR Specification**: https://hl7.org/fhir/R4/
- **HAPI FHIR Docs**: https://hapifhir.io/hapi-fhir/docs/
- **Smile CDR Docs**: https://smilecdr.com/docs/

## Resources Supported

This server supports all FHIR R4 resources including:
- Patient
- Observation
- Encounter
- Condition
- Medication
- MedicationRequest
- And many more...
