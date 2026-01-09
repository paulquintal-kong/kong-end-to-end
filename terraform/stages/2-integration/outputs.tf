output "service_id" {
  description = "Gateway Service ID - Required for Stage 3"
  value       = konnect_gateway_service.fhir_patient_service.id
}

output "service_name" {
  description = "Gateway Service Name"
  value       = konnect_gateway_service.fhir_patient_service.name
}

output "route_id" {
  description = "Route ID"
  value       = konnect_gateway_route.fhir_patient_routes.id
}

output "api_endpoint" {
  description = "Public API Endpoint (via Kong Gateway)"
  value       = "https://${var.control_plane_id}.au.cp0.konghq.com/api/patients"
}

# Output as JSON for easy consumption by next stage
output "stage2_outputs" {
  description = "All outputs from Stage 2 (for Stage 3 input)"
  value = {
    service_id     = konnect_gateway_service.fhir_patient_service.id
    service_name   = konnect_gateway_service.fhir_patient_service.name
    route_id       = konnect_gateway_route.fhir_patient_routes.id
    api_endpoint   = "https://${var.control_plane_id}.au.cp0.konghq.com/api/patients"
  }
  sensitive = false
}
