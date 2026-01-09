# Create FHIR Service in Kong Konnect
resource "konnect_gateway_service" "fhir_patient_service" {
  name            = var.service_name
  protocol        = "https"
  host            = replace(replace(var.fhir_server_url, "https://", ""), "/fhir", "")
  port            = 443
  path            = "/fhir"
  retries         = 5
  connect_timeout = 60000
  write_timeout   = 60000
  read_timeout    = 60000

  tags = var.service_tags

  control_plane_id = konnect_gateway_control_plane.fhir_control_plane.id
}
