variable "konnect_token" {
  description = "Kong Konnect Personal Access Token"
  type        = string
  sensitive   = true
}

# Input from Stage 1
variable "control_plane_id" {
  description = "Control Plane ID from Stage 1 (Platform Engineer)"
  type        = string
}

variable "upstream_url" {
  description = "Backend API URL (e.g., your FHIR server endpoint)"
  type        = string
  default     = "https://asia-bosker-renna.ngrok-free.dev/fhir"
}

variable "api_host" {
  description = "Public hostname for the API"
  type        = string
  default     = "api.patient-records.example.com"
}
