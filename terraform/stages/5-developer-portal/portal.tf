# ========================================================================
# Developer Portal Configuration
# ========================================================================
# Use existing Developer Portal and publish API Product to it
# 
# Key Features:
# - API catalog browsing
# - Interactive API documentation
# - Developer registration and onboarding
# - API key/credential management
# - Application registration
# ========================================================================

# Fetch existing portal
data "konnect_portal" "existing_portal" {
  id = var.portal_id
}

# Publish API Product to the portal
resource "konnect_portal_product_version" "fhir_api_publication" {
  portal_id = data.konnect_portal.existing_portal.id
  
  # Link to the API Product from Stage 4
  product_version_id = var.catalog_api_id
  
  # Publication settings
  publish_status = "published"
  deprecated     = false
  
  # Make it discoverable in the portal
  application_registration_enabled = true
  auto_approve_registration       = false  # Require approval for app registration
}

# ========================================================================
# Next Steps for Demo
# ========================================================================
# After running this stage, demonstrate the 3rd party developer experience:
#
# 1. Visit the portal URL (output above)
# 2. Browse available APIs - you should see the FHIR Patient API
# 3. Register as a developer (if auth enabled)
# 4. Create an application
# 5. Request API credentials
# 6. Test the API with provided credentials
# 7. Monitor usage analytics
# ========================================================================
