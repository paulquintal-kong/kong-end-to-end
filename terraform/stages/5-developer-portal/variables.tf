variable "konnect_token" {
  description = "Kong Konnect Personal Access Token"
  type        = string
  sensitive   = true
}

# Input from Stage 4
variable "catalog_api_id" {
  description = "Catalog API ID from Stage 4"
  type        = string
}

variable "portal_id" {
  description = "Existing Developer Portal ID to publish API to"
  type        = string
}

variable "portal_name" {
  description = "Developer Portal Name (unused - for backwards compatibility)"
  type        = string
  default     = ""
}

variable "portal_display_name" {
  description = "Developer Portal Display Name (unused - for backwards compatibility)"
  type        = string
  default     = ""
}

variable "enable_auth" {
  description = "Require authentication to access portal (unused - portal already configured)"
  type        = bool
  default     = false
}

variable "auto_approve_developers" {
  description = "Automatically approve developer registrations (unused - portal already configured)"
  type        = bool
  default     = false
}
