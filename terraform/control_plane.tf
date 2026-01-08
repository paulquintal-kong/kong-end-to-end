# Create Kong Konnect Control Plane
resource "konnect_gateway_control_plane" "fhir_control_plane" {
  name        = var.control_plane_name
  description = var.control_plane_description
  
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
  
  labels = {
    environment = "development"
    team        = "healthcare"
    api_type    = "fhir"
  }
}

# Output Control Plane Details
output "control_plane_id" {
  description = "ID of the created control plane"
  value       = konnect_gateway_control_plane.fhir_control_plane.id
}

output "control_plane_name" {
  description = "Name of the created control plane"
  value       = konnect_gateway_control_plane.fhir_control_plane.name
}

output "control_plane_endpoint" {
  description = "Control plane endpoint"
  value       = konnect_gateway_control_plane.fhir_control_plane.config.control_plane_endpoint
}
