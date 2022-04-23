terraform {
  backend "azurerm" {
    resource_group_name  = "eultengo-tfstate-rg"
    storage_account_name = "eultengotfstaterampup"
    container_name       = "eultengotfstate"
    key                  = "global/infra/terraform.tfstate"
  }
}