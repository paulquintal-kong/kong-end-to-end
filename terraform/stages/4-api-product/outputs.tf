output "catalog_service_id" {
  description = "Catalog Service ID"
  value       = konnect_catalog_service.fhir_patient_catalog.id
}

output "catalog_service_name" {
  description = "Catalog Service Name"
  value       = konnect_catalog_service.fhir_patient_catalog.name
}

output "catalog_api_id" {
  description = "Catalog API ID - Required for Stage 5"
  value       = konnect_api.fhir_patient_api.id
}

output "api_implementation_id" {
  description = "API Implementation ID"
  value       = konnect_api_implementation.fhir_patient_implementation.id
}

output "rate_limit_plugin_id" {
  description = "Rate Limiting Plugin ID"
  value       = konnect_gateway_plugin_rate_limiting.api_rate_limit.id
}

# Output as JSON for easy consumption by next stage
output "stage4_outputs" {
  description = "All outputs from Stage 4 (for Stage 5 input)"
  value = {
    catalog_service_id    = konnect_catalog_service.fhir_patient_catalog.id
    catalog_api_id        = konnect_api.fhir_patient_api.id
    rate_limit_per_minute = var.rate_limit_per_minute
  }
  sensitive = false
}
