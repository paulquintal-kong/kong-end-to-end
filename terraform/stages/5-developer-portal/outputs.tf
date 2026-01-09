output "portal_id" {
  description = "Developer Portal ID"
  value       = konnect_portal.developer_portal.id
}

output "portal_url" {
  description = "Developer Portal URL - Share with 3rd party developers"
  value       = "https://${konnect_portal.developer_portal.default_domain}"
}

output "portal_domain" {
  description = "Portal Domain"
  value       = konnect_portal.developer_portal.default_domain
}

output "authentication_enabled" {
  description = "Is authentication required to access the portal?"
  value       = konnect_portal.developer_portal.authentication_enabled
}

output "developer_onboarding_message" {
  description = "Instructions for 3rd party developers"
  value = <<-EOT
    
    🎉 Developer Portal is Ready!
    
    Portal URL: https://${konnect_portal.developer_portal.default_domain}
    
    For 3rd Party Developers:
    ${var.enable_auth ? "1. Register for an account at the portal" : "1. Browse APIs (no registration required)"}
    ${var.auto_approve_developers && var.enable_auth ? "2. Instant access granted" : var.enable_auth ? "2. Wait for API owner approval" : "2. Browse API documentation"}
    3. Create an application
    4. Request API credentials
    5. Start building with the API
    
    For API Owners:
    - Manage developers at: https://au.cloud.konghq.com/portals
    - Review applications and approve credentials
    - Monitor API usage analytics
    
  EOT
}

# Output as JSON for consumption
output "stage4_outputs" {
  description = "All outputs from Stage 4"
  value = {
    portal_id              = konnect_portal.developer_portal.id
    portal_url             = "https://${konnect_portal.developer_portal.default_domain}"
    authentication_enabled = konnect_portal.developer_portal.authentication_enabled
  }
  sensitive = false
}
