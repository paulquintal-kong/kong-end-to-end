# ========================================================================
# Gateway Service Configuration
# ========================================================================
# The Gateway Service represents the backend/upstream API
# It defines:
# - Where to route traffic (upstream URL)
# - Connection settings (timeouts, retries)
# - Load balancing behavior
# ========================================================================

resource "konnect_gateway_service" "fhir_patient_service" {
  name             = "Patient-Records-API"
  protocol         = "https"
  host             = split("://", split("/", var.upstream_url)[2])[0]
  port             = 443
  path             = "/fhir"
  
  control_plane_id = var.control_plane_id
  
  # Connection and retry settings
  retries          = 5
  connect_timeout  = 60000
  write_timeout    = 60000
  read_timeout     = 60000
  
  tags = [
    "fhir-r4",
    "patient-api",
    "healthcare",
    "integration-engineer"
  ]
}

# ========================================================================
# Route Configuration
# ========================================================================
# Routes define how clients access the API through Kong Gateway
# They specify:
# - URL paths and patterns
# - HTTP methods allowed
# - Request/response transformations
# ========================================================================

resource "konnect_gateway_route" "fhir_patient_routes" {
  name = "patient-records-routes"
  
  protocols = ["https", "http"]
  methods   = ["GET", "POST", "PUT", "PATCH", "DELETE"]
  
  # Route all /api/patients/* traffic to the FHIR service
  paths = [
    "/api/patients",
    "/api/patients/~"
  ]
  
  strip_path = true
  
  control_plane_id = var.control_plane_id
  
  service = {
    id = konnect_gateway_service.fhir_patient_service.id
  }
  
  tags = [
    "patient-api",
    "public-api"
  ]
}
