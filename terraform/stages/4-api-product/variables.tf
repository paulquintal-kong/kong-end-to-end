variable "konnect_token" {
  description = "Kong Konnect Personal Access Token"
  type        = string
  sensitive   = true
}

# Inputs from Stage 1 (Platform)
variable "control_plane_id" {
  description = "Control Plane ID from Stage 1"
  type        = string
}

# Inputs from Stage 2 (Integration)
variable "service_id" {
  description = "Gateway Service ID from Stage 2"
  type        = string
}

variable "openapi_spec_path" {
  description = "Path to OpenAPI specification file"
  type        = string
  default     = "../../../.insomnia/fhir-api-openapi.yaml"
}

variable "rate_limit_per_minute" {
  description = "API rate limit (requests per minute)"
  type        = number
  default     = 5
}
