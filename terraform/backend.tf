terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "quintalconsultingtfstate"
    container_name       = "kong-fhir-tfstate"
    key                  = "kong-fhir.tfstate"
  }
}
