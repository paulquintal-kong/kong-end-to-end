output "control_plane_id" {
  description = "Kong Gateway Control Plane ID - Required for Stage 2"
  value       = konnect_gateway_control_plane.fhir_control_plane.id
}

output "control_plane_name" {
  description = "Control Plane Name"
  value       = konnect_gateway_control_plane.fhir_control_plane.name
}

output "control_plane_endpoint" {
  description = "Control Plane API Endpoint"
  value       = "https://${konnect_gateway_control_plane.fhir_control_plane.id}.${var.environment == "production" ? "au.cp0" : "dev.au.cp0"}.konghq.com"
}

# Output as JSON for easy consumption by next stage
output "stage1_outputs" {
  description = "All outputs from Stage 1 (for Stage 2 input)"
  value = {
    control_plane_id       = konnect_gateway_control_plane.fhir_control_plane.id
    control_plane_name     = konnect_gateway_control_plane.fhir_control_plane.name
    control_plane_endpoint = "https://${konnect_gateway_control_plane.fhir_control_plane.id}.${var.environment == "production" ? "au.cp0" : "dev.au.cp0"}.konghq.com"
  }
  sensitive = false
}
