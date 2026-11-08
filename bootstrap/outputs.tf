output "github_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

output "tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "external_dns_client_id" {
  value = azurerm_user_assigned_identity.external_dns.client_id
}