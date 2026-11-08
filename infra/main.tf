resource "azurerm_resource_group" "app" {
  name     = "rg-${var.project}"
  location = var.location
}