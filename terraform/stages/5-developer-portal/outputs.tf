output "portal_id" {
  description = "Developer Portal ID"
  value       = var.portal_id
}

output "portal_url" {
  description = "Developer Portal URL - Share with 3rd party developers"
  value       = "Portal ID: ${var.portal_id} - View at https://au.cloud.konghq.com/portals"
}

output "api_published" {
  description = "API Product Version Publication Status"
  value       = konnect_portal_product_version.fhir_api_publication.publish_status
}

output "publication_id" {
  description = "API Publication ID"
  value       = konnect_portal_product_version.fhir_api_publication.id
}

output "developer_onboarding_message" {
  description = "Instructions for 3rd party developers"
  value = <<-EOT
    
    🎉 API Published to Developer Portal!
    
    Portal ID: ${var.portal_id}
    View Portal: https://au.cloud.konghq.com/portals
    
    For 3rd Party Developers:
    1. Visit the portal to discover the FHIR Patient API
    2. Register for an account (if required)
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
output "stage5_outputs" {
  description = "All outputs from Stage 5"
  value = {
    portal_id      = var.portal_id
    api_published  = konnect_portal_product_version.fhir_api_publication.publish_status
    publication_id = konnect_portal_product_version.fhir_api_publication.id
  }
  sensitive = false
}
