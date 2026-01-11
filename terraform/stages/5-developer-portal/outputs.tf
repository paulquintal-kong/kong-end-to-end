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
  value       = konnect_api_publication.fhir_api_publication.visibility
}

output "publication_id" {
  description = "API Publication ID"
  value       = konnect_api_publication.fhir_api_publication.id
}

output "developer_onboarding_message" {
  description = "Instructions for 3rd party developers"
  value = <<-EOT
    
    🎉 API Published to Developer Portal!
    
    Portal ID: ${var.portal_id}
    API Publication ID: ${konnect_api_publication.fhir_api_publication.id}
    Visibility: ${konnect_api_publication.fhir_api_publication.visibility}
    
    Next Steps:
    1. Share the portal URL with developers
    2. Developers can register and create applications
    3. Review and approve application registrations
    4. Monitor API usage and analytics
    
    Portal Management: https://au.cloud.konghq.com/portals
    
  EOT
}

# Output as JSON for consumption
output "stage5_outputs" {
  description = "All outputs from Stage 5"
  value = {
    portal_id      = var.portal_id
    api_published  = konnect_api_publication.fhir_api_publication.visibility
    publication_id = konnect_api_publication.fhir_api_publication.id
  }
  sensitive = false
}
