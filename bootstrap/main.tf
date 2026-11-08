resource "azurerm_resource_group" "bootstrap" {
  name     = "rg-trackance-aks-bootstrap"
  location = "uksouth"
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "trackanceakstfstate"
  resource_group_name             = azurerm_resource_group.bootstrap.name
  location                        = azurerm_resource_group.bootstrap.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_container_registry" "acr" {
  name                = "trackanceaksacr"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
  sku                 = "Basic"
  admin_enabled       = false
}
