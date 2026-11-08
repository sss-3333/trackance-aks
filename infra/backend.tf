terraform {
  backend "azurerm" {
    resource_group_name  = "rg-trackance-aks-bootstrap"
    storage_account_name = "trackanceakstfstate"
    container_name       = "tfstate"
    key                  = "trackance-aks.tfstate"
  }
}