# Service Catalog Entry
# This publishes the gateway service to the Service Hub (Service Catalog)
resource "konnect_catalog_service" "fhir_patient_catalog" {
  name        = "Patient-Records-API"
  description = var.service_purpose
  
  # Link to the gateway service
  service_id = konnect_gateway_service.fhir_patient_service.id
  
  # Service metadata
  tags = concat(var.service_tags, ["catalog", "published"])
  
  # Service documentation
  metadata = {
    contact_team  = var.contact_team
    contact_email = var.contact_email
    architecture  = var.architecture
    dependencies  = var.dependencies
    support_sla   = var.support_sla
    version       = var.service_version
  }
}
