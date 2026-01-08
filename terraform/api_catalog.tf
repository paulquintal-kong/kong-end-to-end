# NEW Catalog API Configuration (v3.0.0+)
# This creates the API in Applications > Catalog > API (the new location)
# Replaces the old konnect_api_product approach

resource "konnect_api" "fhir_patient_api" {
  name        = "Patient Records API"
  version     = "1.0.0"
  description = "FHIR R4 API for Patient, Observation, Encounter, Condition, and Medication resources"
  
  # Include the OpenAPI spec directly in the API resource
  spec_content = file("${path.module}/../.insomnia/fhir-api-openapi.yaml")
  
  # Link to Catalog Service
  attributes = jsonencode({
    catalog_service_id = [konnect_catalog_service.fhir_patient_catalog.id]
  })
  
  labels = {
    environment = "production"
    domain      = "healthcare"
    standard    = "fhir-r4"
  }
}

# Link the API to the Gateway Service (Implementation)
resource "konnect_api_implementation" "fhir_patient_implementation" {
  api_id = konnect_api.fhir_patient_api.id
  
  service_reference = {
    service = {
      control_plane_id = konnect_gateway_control_plane.fhir_control_plane.id
      id              = konnect_gateway_service.fhir_patient_service.id
    }
  }
}
