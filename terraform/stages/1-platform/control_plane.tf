# ========================================================================
# Kong Gateway Control Plane Configuration
# ========================================================================
# The control plane is the central management layer for Kong Gateway
# It provides:
# - Configuration management for data planes
# - Policy enforcement
# - Analytics and monitoring
# - API gateway routing rules
# ========================================================================

resource "konnect_gateway_control_plane" "fhir_control_plane" {
  name        = "FHIR Patient Records Control Plane"
  description = "Control plane for FHIR R4 Patient Records API - manages routing, policies, and data plane configuration"
  
  cluster_type = "CLUSTER_TYPE_CONTROL_PLANE"
  
  labels = {
    environment = var.environment
    project     = var.project_name
    team        = "platform-engineering"
    api_domain  = "healthcare"
  }
}
