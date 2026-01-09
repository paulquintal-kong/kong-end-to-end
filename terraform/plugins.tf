# Kong Gateway Plugins Configuration
# Plugins applied to the Patient Records API gateway service

# Rate Limiting Plugin - Protect the API from excessive requests
# Limits to 5 requests per minute per consumer/IP
resource "konnect_gateway_plugin_rate_limiting" "fhir_patient_rate_limit" {
  enabled = true
  
  control_plane_id = konnect_gateway_control_plane.fhir_control_plane.id
  
  # Apply to the Patient Records service
  service = {
    id = konnect_gateway_service.fhir_patient_service.id
  }
  
  config = {
    minute        = 5
    policy        = "local"
    limit_by      = "consumer"
    hide_client_headers = false
  }
}
