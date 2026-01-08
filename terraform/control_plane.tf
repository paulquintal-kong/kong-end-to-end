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
