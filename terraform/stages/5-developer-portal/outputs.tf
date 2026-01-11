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
  value       = "manual_step_required"
}

output "publication_id" {
  description = "API Publication ID"
  value       = "Publish manually via UI"
}

output "developer_onboarding_message" {
  description = "Instructions for 3rd party developers"
  value = <<-EOT
    
    📋 Manual Step Required - Portal v3 Limitation
    
    Portal ID: ${var.portal_id}
    API Product ID: ${var.catalog_api_id}
    
    To publish the API to your developer portal:
    1. Visit https://au.cloud.konghq.com/portals
    2. Select your portal
    3. Go to API Products → Publish API Product
    4. Select the FHIR Patient API
    5. Configure and publish
    
    After publishing:
    - Share the portal URL with developers
    - Manage applications and credentials
    - Monitor API usage and analytics
    
  EOT
}

# Output as JSON for consumption
output "stage5_outputs" {
  description = "All outputs from Stage 5"
  value = {
    portal_id      = var.portal_id
    api_published  = "manual_step_required"
    publication_id = "Publish via UI: https://au.cloud.konghq.com/portals"
  }
  sensitive = false
}
