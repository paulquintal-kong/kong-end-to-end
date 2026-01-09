# ========================================================================
# API Governance Policies - Rate Limiting
# ========================================================================
# Persona: API Owner / Platform Team
# Purpose: Protect APIs from abuse and ensure fair usage
# 
# Rate limiting prevents:
# - API abuse and DDoS attacks
# - Resource exhaustion
# - Unfair consumption by single consumers
# 
# This demonstrates API governance at the product level
# ========================================================================

resource "konnect_gateway_plugin_rate_limiting" "api_rate_limit" {
  enabled = true
  
  control_plane_id = var.control_plane_id
  
  # Apply to the Patient Records service
  service = {
    id = var.service_id
  }
  
  config = {
    minute              = var.rate_limit_per_minute
    policy              = "local"
    limit_by            = "consumer"  # Rate limit per consumer (or IP if no auth)
    hide_client_headers = false       # Show rate limit headers in response
  }
}

# ========================================================================
# Future Governance Policies (Examples for Demo)
# ========================================================================
# Uncomment these to demonstrate additional governance capabilities:
#
# 1. CORS Plugin - Enable cross-origin requests
# resource "konnect_gateway_plugin_cors" "api_cors" {
#   enabled          = true
#   control_plane_id = var.control_plane_id
#   service = { id = var.service_id }
#   
#   config = {
#     origins     = ["*"]
#     methods     = ["GET", "POST", "PUT", "PATCH", "DELETE"]
#     headers     = ["Accept", "Content-Type", "Authorization"]
#     credentials = true
#   }
# }
#
# 2. Request Transformer - Modify requests
# resource "konnect_gateway_plugin_request_transformer" "add_headers" {
#   enabled          = true
#   control_plane_id = var.control_plane_id
#   service = { id = var.service_id }
#   
#   config = {
#     add = {
#       headers = ["X-API-Version:1.0", "X-Environment:production"]
#     }
#   }
# }
#
# 3. Key Authentication - API key security
# resource "konnect_gateway_plugin_key_auth" "api_key_auth" {
#   enabled          = true
#   control_plane_id = var.control_plane_id
#   service = { id = var.service_id }
#   
#   config = {
#     key_names = ["apikey", "X-API-Key"]
#   }
# }
