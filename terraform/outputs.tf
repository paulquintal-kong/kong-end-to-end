output "control_plane_id" {
  description = "ID of the Kong Konnect control plane"
  value       = konnect_gateway_control_plane.fhir_control_plane.id
}

output "control_plane_name" {
  description = "Name of the Kong Konnect control plane"
  value       = konnect_gateway_control_plane.fhir_control_plane.name
}

output "control_plane_endpoint" {
  description = "Endpoint URL of the Kong Konnect control plane"
  value       = konnect_gateway_control_plane.fhir_control_plane.config.control_plane_endpoint
}

output "service_id" {
  description = "ID of the Kong gateway service"
  value       = konnect_gateway_service.fhir_patient_service.id
}

output "service_name" {
  description = "Name of the Kong gateway service"
  value       = konnect_gateway_service.fhir_patient_service.name
}

output "service_url" {
  description = "Full URL of the Kong gateway service"
  value       = "https://${konnect_gateway_service.fhir_patient_service.host}${konnect_gateway_service.fhir_patient_service.path}"
}

output "catalog_service_id" {
  description = "ID of the Service Hub catalog entry"
  value       = konnect_catalog_service.fhir_patient_catalog.id
}

output "catalog_service_name" {
  description = "Display name of the Service Hub catalog entry"
  value       = konnect_catalog_service.fhir_patient_catalog.display_name
}
