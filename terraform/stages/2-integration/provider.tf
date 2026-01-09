# ========================================================================
# STAGE 2: INTEGRATION ENGINEER - API Gateway Configuration
# ========================================================================
# Persona: Integration/Backend Engineer
# Responsibility: Configure gateway services and routes for APIs
# 
# What this stage demonstrates:
# - Connecting Kong Gateway to upstream services
# - Configuring routes and traffic routing
# - Setting up API endpoints
# - Basic connectivity testing
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
    key    = "stage2-integration/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

provider "konnect" {
  personal_access_token = var.konnect_token
  server_url            = "https://au.api.konghq.com"
}
