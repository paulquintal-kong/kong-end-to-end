# ========================================================================
# STAGE 4: API OWNER - Developer Portal Publishing
# ========================================================================
# Persona: API Product Manager / Developer Experience Lead
# Responsibility: Publish APIs to developer portal for external consumption
# 
# What this stage demonstrates:
# - Creating and configuring the developer portal
# - Publishing APIs to the portal
# - Managing API discovery for 3rd party developers
# - Setting up developer onboarding workflows
# ========================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "3.4.3"
    }
  }
  
  backend "s3" {
    bucket = "kong-fhir-tfstate"
    key    = "stage4-developer-portal/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

provider "konnect" {
  personal_access_token = var.konnect_token
  server_url            = "https://au.api.konghq.com"
}
