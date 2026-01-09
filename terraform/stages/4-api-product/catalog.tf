# ========================================================================
# Catalog Service Entry
# ========================================================================
# The Catalog Service is the organizational unit in Kong Konnect
# It represents a business capability or domain service
# Think of it as a "microservice" in your architecture
# ========================================================================

resource "konnect_catalog_service" "fhir_patient_catalog" {
  name        = "Patient Records API"
  description = "FHIR R4 compliant API for managing patient medical records and health information"
  
  labels = {
    domain      = "healthcare"
    standard    = "fhir-r4"
    compliance  = "hipaa-ready"
    owner       = "api-product-team"
  }
  
  custom_fields = {
    api_owner        = "healthcare-api-team@example.com"
    sla_tier         = "gold"
    support_channel  = "#healthcare-apis"
    documentation    = "https://hl7.org/fhir/R4/"
  }
}

# ========================================================================
# Catalog API Entry
# ========================================================================
# The API represents a versioned API contract
# It includes the OpenAPI specification and links to services
# This is what API consumers discover in the catalog
# ========================================================================

resource "konnect_api" "fhir_patient_api" {
  name    = "Patient Records API"
  version = "1.0.0"
  
  spec_content = file(var.openapi_spec_path)
  
  # Link this API to the Catalog Service
  attributes = jsonencode({
    catalog_service_id = [konnect_catalog_service.fhir_patient_catalog.id]
  })
  
  labels = {
    environment = "production"
    domain      = "healthcare"
    standard    = "fhir-r4"
    version     = "1.0.0"
  }
}

# ========================================================================
# API Specification
# ========================================================================
# The specification provides the OpenAPI/Swagger contract
# This is displayed in the catalog and portal for documentation
# ========================================================================

resource "konnect_api_specification" "fhir_patient_spec" {
  api_id  = konnect_api.fhir_patient_api.id
  content = file(var.openapi_spec_path)
  type    = "oas3"
}

# ========================================================================
# API Implementation
# ========================================================================
# Links the Catalog API to the actual Gateway Service
# This connects the "product" (API) to the "implementation" (service)
# ========================================================================

resource "konnect_api_implementation" "fhir_patient_implementation" {
  api_id = konnect_api.fhir_patient_api.id
  
  service_reference = {
    service = {
      control_plane_id = var.control_plane_id
      id               = var.service_id
    }
  }
}
