# Kong Konnect PAT Token (stored in GitHub Secrets)
variable "konnect_pat" {
  description = "Kong Konnect Personal Access Token"
  type        = string
  sensitive   = true
}

# FHIR Server Ngrok URL (updated by start_demo.sh)
variable "fhir_server_url" {
  description = "FHIR Server URL (ngrok tunnel endpoint)"
  type        = string
  default     = "https://placeholder.ngrok-free.dev/fhir"
}

# Control Plane Configuration
variable "control_plane_name" {
  description = "Name of the Kong Konnect Control Plane"
  type        = string
  default     = "FHIR Patient Records Control Plane"
}

variable "control_plane_description" {
  description = "Description of the Control Plane"
  type        = string
  default     = "Control plane for FHIR-based Patient Records API services"
}

# Service Catalog Configuration
variable "service_name" {
  description = "Name of the service in Kong catalog"
  type        = string
  default     = "Patient-Records-API"
}

variable "service_tags" {
  description = "Tags for the service"
  type        = list(string)
  default     = ["FHIR", "Healthcare", "Patient Data"]
}

# Service Documentation
variable "service_purpose" {
  description = "Purpose of the service"
  type        = string
  default     = "Provides FHIR R4 compliant API for patient demographic and clinical data management. Supports creating, reading, updating, and searching patient records, observations, encounters, conditions, and medications."
}

variable "service_contact_team" {
  description = "Contact team for the service"
  type        = string
  default     = "Healthcare Integration Team"
}

variable "service_contact_email" {
  description = "Contact email for the service"
  type        = string
  default     = "fhir-support@example.com"
}

variable "service_architecture" {
  description = "Architecture details of the service"
  type        = string
  default     = <<-EOT
    Architecture: RESTful FHIR R4 API
    - Backend: HAPI FHIR Server v8.6.0
    - Database: H2 In-Memory (Development)
    - Authentication: OAuth2 / API Key
    - Protocol: HTTPS
    - Data Format: JSON (application/fhir+json)
    - API Gateway: Kong Gateway
    - Tunnel: Ngrok (Development Environment)
  EOT
}

variable "service_dependencies" {
  description = "Service dependencies"
  type        = string
  default     = <<-EOT
    Dependencies:
    - HAPI FHIR Server (v8.6.0+)
    - H2 Database
    - Kong Gateway
    - Ngrok (Development)
    - OAuth2 Identity Provider (Production)
    
    External APIs: None
    Internal Services: None
  EOT
}

variable "service_support_sla" {
  description = "Support SLA details"
  type        = string
  default     = <<-EOT
    Support Details:
    - Business Hours: 9 AM - 5 PM AEST (Monday-Friday)
    - Response Time: 4 hours for P1, 24 hours for P2/P3
    - Escalation: fhir-escalation@example.com
    - Documentation: https://github.com/your-org/fhir-api
    - Status Page: https://status.example.com
    - Slack Channel: #fhir-api-support
  EOT
}

variable "service_version" {
  description = "Service API version"
  type        = string
  default     = "1.0.1"
}
