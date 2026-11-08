resource "azurerm_resource_group" "app" {
  name     = "rg-${var.project}"
  location = var.location
}

module "network" {
  source              = "./modules/network"
  name                = var.project
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
}

data "azurerm_container_registry" "acr" {
  name                = "trackanceaksacr"
  resource_group_name = "rg-trackance-aks-bootstrap"
}

module "aks" {
  source              = "./modules/aks"
  name                = var.project
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  subnet_id           = module.network.subnet_id
  acr_id              = data.azurerm_container_registry.acr.id
}