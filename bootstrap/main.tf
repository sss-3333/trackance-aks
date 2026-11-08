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

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-trackance-aks-github"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
}

resource "azurerm_federated_identity_credential" "github_main" {
  name                      = "github-main"
  user_assigned_identity_id = azurerm_user_assigned_identity.github.id
  issuer                    = "https://token.actions.githubusercontent.com"
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "repo:sss-3333@120253226/trackance-aks@1449856814:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "github_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "github_acr_rbac_admin" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
  condition_version    = "2.0"
  condition            = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
      )
      OR
      (
        @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d}
      )
    )
    AND
    (
      (
        !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
      )
      OR
      (
        @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d}
      )
    )
  EOT
}

resource "azurerm_role_assignment" "github_aks_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "me_aks_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_dns_zone" "labs" {
  name                = "labs.trackance.co.uk"
  resource_group_name = azurerm_resource_group.bootstrap.name
}

data "aws_route53_zone" "parent" {
  name = "trackance.co.uk"
}

resource "aws_route53_record" "labs_ns" {
  zone_id = data.aws_route53_zone.parent.zone_id
  name    = "labs.trackance.co.uk"
  type    = "NS"
  ttl     = 300
  records = azurerm_dns_zone.labs.name_servers
}

resource "azurerm_user_assigned_identity" "external_dns" {
  name                = "id-trackance-external-dns"
  resource_group_name = azurerm_resource_group.bootstrap.name
  location            = azurerm_resource_group.bootstrap.location
}

resource "azurerm_role_assignment" "external_dns_zone" {
  scope                = azurerm_dns_zone.labs.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "external_dns_reader" {
  scope                = azurerm_resource_group.bootstrap.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
  principal_type       = "ServicePrincipal"
}