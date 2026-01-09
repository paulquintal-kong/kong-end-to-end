# ========================================================================
# STAGE 1: PLATFORM ENGINEER - Infrastructure Foundation
# ========================================================================
# Persona: Platform/DevOps Engineer
# Responsibility: Set up Kong Gateway infrastructure and control planes
# 
# What this stage demonstrates:
# - Provisioning Kong Konnect control plane
# - Establishing baseline infrastructure
# - Setting up the foundation for API management
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
    key    = "stage1-platform/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

provider "konnect" {
  personal_access_token = var.konnect_token
  server_url            = "https://au.api.konghq.com"
}
