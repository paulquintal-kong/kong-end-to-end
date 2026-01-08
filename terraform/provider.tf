# Kong Konnect Provider Configuration
terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "~> 0.9.0"
    }
  }
  required_version = ">= 1.0"
}

provider "konnect" {
  personal_access_token = var.konnect_pat
  server_url           = "https://au.api.konghq.com"
}
