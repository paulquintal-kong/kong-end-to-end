# Service Catalog Entry
# This publishes the service to the Kong Konnect Service Hub (Service Catalog)
# Note: This is separate from the gateway service - it creates a catalog entry
# that can be discovered in the Service Hub
resource "konnect_catalog_service" "fhir_patient_catalog" {
  # Machine-readable name (must be lowercase, no spaces)
  name = "patient-records-api"

  # Human-readable display name (REQUIRED)
  display_name = "Patient Records API"

  # Service description - include all metadata here since custom_fields has restrictions
  description = <<-EOT
    ${var.service_purpose}
    
    Contact: ${var.service_contact_team} (${var.service_contact_email})
    Version: ${var.service_version}
    FHIR Version: R4
    
    ${var.service_architecture}
    
    ${var.service_dependencies}
    
    ${var.service_support_sla}
  EOT

  # Labels for categorization and filtering in Service Hub
  # Use labels to store key metadata for filtering/searching
  labels = {
    environment        = "development"
    team               = "healthcare"
    api_type           = "fhir"
    fhir_version       = "r4"
    resource_type      = "patient"
    version            = "1-0-1"
    gateway_service_id = konnect_gateway_service.fhir_patient_service.id
  }

  # Note: custom_fields is not used because Kong Konnect requires predefined fields
  # and doesn't allow arbitrary properties. All metadata is in description and labels.

  depends_on = [konnect_gateway_service.fhir_patient_service]
}
