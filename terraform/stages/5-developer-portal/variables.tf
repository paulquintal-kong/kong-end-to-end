variable "konnect_token" {
  description = "Kong Konnect Personal Access Token"
  type        = string
  sensitive   = true
}

# Input from Stage 3
variable "catalog_api_id" {
  description = "Catalog API ID from Stage 3"
  type        = string
}

variable "portal_name" {
  description = "Developer Portal Name"
  type        = string
  default     = "Patient Records API"
}

variable "portal_display_name" {
  description = "Developer Portal Display Name"
  type        = string
  default     = "Developer Portal"
}

variable "enable_auth" {
  description = "Require authentication to access portal"
  type        = bool
  default     = false
}

variable "auto_approve_developers" {
  description = "Automatically approve developer registrations"
  type        = bool
  default     = false
}
