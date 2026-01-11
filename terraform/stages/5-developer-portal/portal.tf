# ========================================================================
# Developer Portal Configuration
# ========================================================================
# NOTE: Portal v3 does not support programmatic API product publishing
# via Terraform or REST API at this time.
#
# To publish your API product to the developer portal:
# 1. Go to https://au.cloud.konghq.com/portals
# 2. Select your portal
# 3. Navigate to API Products
# 4. Click "Publish API Product"
# 5. Select the FHIR Patient API product
# 6. Configure publication settings
# 7. Click "Publish"
#
# This is a placeholder resource to track portal configuration
# ========================================================================

resource "null_resource" "portal_instructions" {
  triggers = {
    portal_id      = var.portal_id
    catalog_api_id = var.catalog_api_id
    timestamp      = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo ""
      echo "=========================================="
      echo "📋 MANUAL STEP REQUIRED"
      echo "=========================================="
      echo ""
      echo "Portal v3 does not support automated API publishing via Terraform."
      echo ""
      echo "To publish your API product to the developer portal:"
      echo ""
      echo "1. Go to: https://au.cloud.konghq.com/portals"
      echo "2. Select portal ID: ${var.portal_id}"
      echo "3. Navigate to 'API Products' section"
      echo "4. Click 'Publish API Product'"
      echo "5. Select your FHIR Patient API (ID: ${var.catalog_api_id})"
      echo "6. Configure publication settings:"
      echo "   - Publish Status: Published"
      echo "   - Enable Application Registration: Yes"
      echo "   - Auto-approve Registration: No"
      echo "7. Click 'Publish'"
      echo ""
      echo "=========================================="
      echo ""
    EOT
  }
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
