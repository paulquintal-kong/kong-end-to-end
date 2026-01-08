# Service Catalog Entry
# This publishes the service to the Kong Konnect Service Hub (Service Catalog)
# Note: This is separate from the gateway service - it creates a catalog entry
# that can be discovered in the Service Hub
resource "konnect_catalog_service" "fhir_patient_catalog" {
  # Machine-readable name (must be lowercase, no spaces)
  name = "patient-records-api"

  # Human-readable display name (REQUIRED)
  display_name = "Patient Records API"

  # Service description
  description = var.service_purpose

  # Labels for categorization and filtering in Service Hub
  labels = {
    environment       = "development"
    team              = "healthcare"
    api_type          = "fhir"
    resource_type     = "patient"
    catalog_published = "true"
  }

  # Custom fields with service metadata (stored as JSON string)
  # This includes link to the gateway service for reference
  custom_fields = jsonencode({
    contact_email        = var.service_contact_email
    contact_team         = var.service_contact_team
    architecture_details = var.service_architecture
    dependencies         = var.service_dependencies
    support_sla          = var.service_support_sla
    api_version          = var.service_version
    fhir_version         = "R4"
    gateway_service_id   = konnect_gateway_service.fhir_patient_service.id
    gateway_service_name = konnect_gateway_service.fhir_patient_service.name
  })

  depends_on = [konnect_gateway_service.fhir_patient_service]
}
