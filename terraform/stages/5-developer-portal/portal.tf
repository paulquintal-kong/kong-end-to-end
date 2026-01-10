# ========================================================================
# Developer Portal Configuration
# ========================================================================
# The Developer Portal is where external developers discover and
# consume your APIs
# 
# Key Features:
# - API catalog browsing
# - Interactive API documentation
# - Developer registration and onboarding
# - API key/credential management
# - Application registration
# ========================================================================

resource "konnect_portal" "developer_portal" {
  name         = var.portal_name
  display_name = var.portal_display_name
  
  # Authentication and Access Control
  # Demo Modes:
  # - Public Portal (authentication_enabled = false): Let anyone browse APIs
  # - Private Portal (authentication_enabled = true): Require login to view
  authentication_enabled    = var.enable_auth
  rbac_enabled             = false
  
  # Developer Onboarding Workflow
  # Demo Modes:
  # - Self-service (auto_approve = true): Developers get instant access
  # - Controlled (auto_approve = false): API owner approves each developer
  auto_approve_developers   = var.auto_approve_developers
  auto_approve_applications = false  # Always require approval for app credentials
  
  # Default Visibility Settings
  default_api_visibility  = "public"  # New APIs are publicly visible by default
  default_page_visibility = "public"  # Portal pages are public
  
  labels = {
    environment = "production"
    team        = "api-product"
    purpose     = "external-developers"
  }
}

# ========================================================================
# Next Steps for Demo
# ========================================================================
# After running this stage, demonstrate the 3rd party developer experience:
#
# 1. Visit the portal URL (output above)
# 2. Browse available APIs
# 3. Register as a developer (if auth enabled)
# 4. Create an application
# 5. Request API credentials
# 6. Test the API with provided credentials
# 7. Monitor usage analytics
# ========================================================================
