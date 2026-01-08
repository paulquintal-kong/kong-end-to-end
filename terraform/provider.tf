# Kong Konnect Provider Configuration
terraform {
  required_providers {
    konnect = {
      source  = "kong/konnect"
      version = "3.4.3"  # Latest stable version with konnect_api resources
    }
  }
  required_version = ">= 1.0"
}

provider "konnect" {
  personal_access_token = var.konnect_pat
  server_url            = "https://au.api.konghq.com"
}
