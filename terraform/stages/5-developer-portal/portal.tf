# ========================================================================
# Developer Portal Configuration
# ========================================================================
# Use existing Developer Portal and publish API Product to it
# 
# Note: Using null_resource with API calls because the Terraform provider's
# konnect_portal_product_version resource only supports v2 portals.
# This portal is v3, so we use the v3 API directly.
# ========================================================================

# Publish API Product to the existing portal using Konnect API
resource "null_resource" "publish_to_portal" {
  triggers = {
    portal_id          = var.portal_id
    catalog_api_id     = var.catalog_api_id
    publish_status     = "published"
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      # Publish the API product version to the portal
      RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
        "https://au.api.konghq.com/v3/portals/${var.portal_id}/product-versions" \
        -H "Authorization: Bearer ${var.konnect_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "product_version_id": "${var.catalog_api_id}",
          "publish_status": "published",
          "deprecated": false,
          "application_registration_enabled": true,
          "auto_approve_registration": false,
          "auth_strategy_ids": []
        }')
      
      HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
      BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')
      
      echo "Response (HTTP $HTTP_CODE):"
      echo "$BODY" | jq '.' || echo "$BODY"
      
      if [ "$HTTP_CODE" != "201" ] && [ "$HTTP_CODE" != "200" ]; then
        echo "Failed to publish API to portal"
        exit 1
      fi
      
      # Save publication ID for outputs
      echo "$BODY" | jq -r '.id' > ${path.module}/.publication_id
    EOT
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Note: Manual cleanup may be required in the portal UI"
    EOT
  }
}

# Read publication ID from file
data "local_file" "publication_id" {
  depends_on = [null_resource.publish_to_portal]
  filename   = "${path.module}/.publication_id"
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
