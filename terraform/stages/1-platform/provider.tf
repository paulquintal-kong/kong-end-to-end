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
  
  # Backend configuration provided via:
  # - AWS S3: terraform init -backend-config=backend-aws.tfbackend
  # - Azure: terraform init -backend-config=backend-azure.tfbackend
  # Use -reconfigure flag when switching backends
  backend "s3" {}
}

provider "konnect" {
  personal_access_token = var.konnect_token
  server_url            = "https://au.api.konghq.com"
}
