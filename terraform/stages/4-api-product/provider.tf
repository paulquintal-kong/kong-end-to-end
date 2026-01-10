# ========================================================================
# STAGE 3: API OWNER - API Productization & Governance
# ========================================================================
# Persona: API Product Manager / API Owner
# Responsibility: Manage API catalog, governance, and policies
# 
# What this stage demonstrates:
# - Publishing APIs to the internal catalog
# - Managing API specifications (OpenAPI/Swagger)
# - Implementing governance policies (rate limiting, security)
# - Creating API products for consumption
# - Linking APIs to services (implementation)
# ========================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "3.4.3"
    }
  }
  
  # Backend configuration provided via:
  # - Azure: terraform init -backend-config=backend-azure.tfbackend
  # Use -reconfigure flag when switching backends
  backend "azurerm" {}
}

provider "konnect" {
  personal_access_token = var.konnect_token
  server_url            = "https://au.api.konghq.com"
}
