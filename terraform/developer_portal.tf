# Developer Portal Configuration
# V3 Portal for Patient Records API documentation and developer onboarding
#
# Portal ID: 519551c7-565e-4031-bd8e-8e5d50af25f2
# Portal URL: https://d89b009b6d6e.au.kongportals.com
#
# Imported pages:
# - / (Kong API) - Home page
# - /apis - API catalog listing
# - /getting-started - Getting started guide
# - /guides - Parent guides page
#   - /document-apis - How to document APIs
#   - /publish-apis - How to publish APIs
#     - /versioning - API versioning best practices

resource "konnect_portal" "patient_records_portal" {
  name                = "Patient Records API"
  display_name        = "Developer Portal"
  
  # Authentication and access controls
  authentication_enabled = false  # Set to true to require login
  auto_approve_developers = false # Require admin approval for new developers
  auto_approve_applications = false # Require admin approval for new applications
  rbac_enabled        = false  # Enable role-based access control
  
  # Default visibility settings
  default_api_visibility  = "public"  # APIs are public by default
  default_page_visibility = "public"  # Pages are public by default
  
  # Labels for organization
  labels = {
    environment = "production"
    api_type    = "fhir"
    team        = "healthcare"
  }
}

# Note: To publish APIs to the portal, you need to:
# 1. Create an API Product using konnect_api_product resource
# 2. Create a product version
# 3. Link it to the portal using konnect_portal_product_version
#
# Currently, the Patient Records API is managed via konnect_api (Catalog API)
# which is separate from API Products. To publish to the portal, you would need
# to also create an API Product or migrate to the API Product model.

# Portal outputs
output "portal_id" {
  value       = konnect_portal.patient_records_portal.id
  description = "Developer Portal ID"
}

output "portal_url" {
  value       = "https://${konnect_portal.patient_records_portal.default_domain}"
  description = "Developer Portal URL"
}

output "portal_default_domain" {
  value       = konnect_portal.patient_records_portal.default_domain
  description = "Portal default domain"
}
