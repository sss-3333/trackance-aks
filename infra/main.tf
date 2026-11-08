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