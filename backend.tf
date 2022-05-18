terraform {
  backend "azurerm" {
    subscription_id      = "1afd90be-5a70-487b-83b4-88571e23e1ee"
    resource_group_name  = "eultengo-tfstate-rg"
    storage_account_name = "eultengotfstateamweek"
    container_name       = "eultengotfstate"
    key                  = "global/infra/terraform.tfstate"
  }
}

