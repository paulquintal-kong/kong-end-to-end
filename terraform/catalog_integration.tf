# GitHub Integration for Catalog
# This links the Kong Konnect Catalog to your GitHub repository
# allowing you to sync API specs, documentation, and metadata from source control

# IMPORTANT: GitHub integration requires GitHub App installation
# The integration instance is created via Terraform, but authorization must be done via the UI

# GitHub Integration Instance
resource "konnect_integration_instance" "github_catalog" {
  name             = "kong-end-to-end-github"
  display_name     = "Kong End-to-End GitHub Integration"
  description      = "GitHub integration for syncing FHIR API specifications and catalog metadata from the kong-end-to-end repository"
  integration_name = "github"
  
  # Config is managed by the integration after GitHub App installation
  config = jsonencode({})
}

# Output the integration ID for reference
output "github_integration_id" {
  value       = konnect_integration_instance.github_catalog.id
  description = "GitHub Catalog Integration Instance ID - use this to complete authorization in the UI"
}

output "github_integration_authorized" {
  value       = konnect_integration_instance.github_catalog.authorized
  description = "Whether the GitHub integration has been authorized (will be false until GitHub App is installed)"
}

# SETUP INSTRUCTIONS:
# After applying this configuration:
# 1. Go to Kong Konnect UI: Applications > Catalog > Integrations
# 2. Find "Kong End-to-End GitHub Integration"
# 3. Click "Authorize" or "Configure"
# 4. Install the Kong GitHub App on your paulquintal-kong/kong-end-to-end repository
# 5. Grant required permissions (repo read access)
# 6. Configure sync settings:
#    - Repository: paulquintal-kong/kong-end-to-end
#    - Branch: main
#    - Path: .insomnia (for API specs)
# 7. Link to Catalog Service (Patient Records API)
