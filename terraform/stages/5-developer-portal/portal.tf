# ========================================================================
# Developer Portal Configuration
# ========================================================================
# Publish API to existing Developer Portal (v3 compatible)
# 
# Uses konnect_api_publication resource to link the API to the portal
# This works with both v2 and v3 portals
# ========================================================================

# Publish API to the portal
resource "konnect_api_publication" "fhir_api_publication" {
  api_id    = var.catalog_api_id
  portal_id = var.portal_id
  
  # Publication settings
  visibility                 = "public"
  auto_approve_registrations = false
  
  # Authentication strategies (empty list uses portal default)
  auth_strategy_ids = []
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
