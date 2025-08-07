# Make sure the resource group has a few key Azure Policies applied to it. These could also be applied at the subscription
# or management group level.  Applying locally to the resource group is useful for testing and development purposes.

# This is just a sampling of the types of policy you could apply to your resource group.  Please make sure your production deployment
# has all policies applied that are relevant to your workload.  Most of these policies can be applied in 'Deny' mode, but in case you
# need to troubleshoot some of the resources, we've left them in 'Audit' mode for now.

# Get current resource group data
data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Existing built-in policy definitions

# Policy definition for ensuring Azure AI Services resources have key access disabled to improve security posture
data "azurerm_policy_definition" "ai_services_key_access" {
  name = "71ef260a-8f18-47b7-abcb-62d0673d94dc"
}

# Policy definition for restricting network access to Azure AI Services resources to prevent unauthorized access
data "azurerm_policy_definition" "ai_services_network_access" {
  name = "037eea7a-bd0a-46c5-9a66-03aea78705d3"
}

# Policy definition for ensuring Cosmos DB accounts are configured with zone redundancy for high availability
data "azurerm_policy_definition" "cosmos_db_zone_redundant" {
  name = "44c5a1f9-7ef6-4c38-880c-273e8f7a3c24"
}

# Policy definition for ensuring Cosmos DB accounts use private endpoints for secure connectivity
data "azurerm_policy_definition" "cosmos_db_private_link" {
  name = "58440f8a-10c5-4151-bdce-dfbaad4a20b7"
}

# Policy definition for disabling local authentication methods on Cosmos DB accounts to improve security
data "azurerm_policy_definition" "cosmos_db_disable_local_auth" {
  name = "5450f5bd-9c72-4390-a9c4-a7aba4edfdd2"
}

# Policy definition for disabling public network access on Cosmos DB accounts to enhance security
data "azurerm_policy_definition" "cosmos_db_disable_public_network" {
  name = "797b37f7-06b8-444c-b1ad-fc62867f335a"
}

# Policy definition for disabling public network access on Azure AI Search services to enhance security
data "azurerm_policy_definition" "search_disable_public_network" {
  name = "ee980b6d-0eca-4501-8d54-f6290fd512c3"
}

# Policy definition for ensuring Azure AI Search services are configured with zone redundancy for high availability
data "azurerm_policy_definition" "search_zone_redundant" {
  name = "90bc8109-d21a-4692-88fc-51419391da3d"
}

# Policy definition for disabling local authentication methods on Azure AI Search services to improve security
data "azurerm_policy_definition" "search_disable_local_auth" {
  name = "6300012e-e9a4-4649-b41f-a85f5c43be91"
}

# Policy definition for disabling public network access on Storage accounts to enhance security
data "azurerm_policy_definition" "storage_disable_public_network" {
  name = "b2982f36-99f2-4db5-8eff-283140c09693"
}

# Policy definition for preventing shared key access on Storage accounts to improve security posture
data "azurerm_policy_definition" "storage_disable_shared_key" {
  name = "8c6a50c6-9ffd-4ae7-986f-5fa6111f9a54"
}

# ---- New resources (Policy assignments) ----

# Policy assignment to audit Azure AI Services resources and ensure key access is disabled for enhanced security
resource "azurerm_resource_group_policy_assignment" "ai_services_key_access" {
  name                 = substr("${var.base_name}-ai-key-access", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.ai_services_key_access.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.ai_services_key_access.display_name}"
  description          = data.azurerm_policy_definition.ai_services_key_access.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit and restrict network access for Azure AI Services resources to improve security posture
resource "azurerm_resource_group_policy_assignment" "ai_services_network_access" {
  name                 = substr("${var.base_name}-ai-network", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.ai_services_network_access.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.ai_services_network_access.display_name}"
  description          = data.azurerm_policy_definition.ai_services_network_access.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Cosmos DB accounts and ensure zone redundancy is configured for high availability
resource "azurerm_resource_group_policy_assignment" "cosmos_db_zone_redundant" {
  name                 = substr("${var.base_name}-cosmos-zone", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.cosmos_db_zone_redundant.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.cosmos_db_zone_redundant.display_name}"
  description          = data.azurerm_policy_definition.cosmos_db_zone_redundant.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Cosmos DB accounts and ensure they use private endpoints for secure connectivity
resource "azurerm_resource_group_policy_assignment" "cosmos_db_private_link" {
  name                 = substr("${var.base_name}-cosmos-pe", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.cosmos_db_private_link.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.cosmos_db_private_link.display_name}"
  description          = data.azurerm_policy_definition.cosmos_db_private_link.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Cosmos DB accounts and ensure local authentication methods are disabled for improved security
resource "azurerm_resource_group_policy_assignment" "cosmos_db_disable_local_auth" {
  name                 = substr("${var.base_name}-cosmos-auth", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.cosmos_db_disable_local_auth.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.cosmos_db_disable_local_auth.display_name}"
  description          = data.azurerm_policy_definition.cosmos_db_disable_local_auth.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Cosmos DB accounts and ensure public network access is disabled to enhance security
resource "azurerm_resource_group_policy_assignment" "cosmos_db_disable_public_network" {
  name                 = substr("${var.base_name}-cosmos-net", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.cosmos_db_disable_public_network.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.cosmos_db_disable_public_network.display_name}"
  description          = data.azurerm_policy_definition.cosmos_db_disable_public_network.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Azure AI Search services and ensure public network access is disabled for enhanced security
resource "azurerm_resource_group_policy_assignment" "search_disable_public_network" {
  name                 = substr("${var.base_name}-search-net", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.search_disable_public_network.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.search_disable_public_network.display_name}"
  description          = data.azurerm_policy_definition.search_disable_public_network.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Azure AI Search services and ensure zone redundancy is configured for high availability
resource "azurerm_resource_group_policy_assignment" "search_zone_redundant" {
  name                 = substr("${var.base_name}-search-zone", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.search_zone_redundant.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.search_zone_redundant.display_name}"
  description          = data.azurerm_policy_definition.search_zone_redundant.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Azure AI Search services and ensure local authentication methods are disabled for improved security
resource "azurerm_resource_group_policy_assignment" "search_disable_local_auth" {
  name                 = substr("${var.base_name}-search-auth", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.search_disable_local_auth.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.search_disable_local_auth.display_name}"
  description          = data.azurerm_policy_definition.search_disable_local_auth.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Storage accounts and ensure public network access is disabled for enhanced security
resource "azurerm_resource_group_policy_assignment" "storage_disable_public_network" {
  name                 = substr("${var.base_name}-stor-net", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.storage_disable_public_network.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.storage_disable_public_network.display_name}"
  description          = data.azurerm_policy_definition.storage_disable_public_network.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Policy assignment to audit Storage accounts and ensure shared key access is prevented for improved security posture
resource "azurerm_resource_group_policy_assignment" "storage_disable_shared_key" {
  name                 = substr("${var.base_name}-stor-key", 0, 24)
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = data.azurerm_policy_definition.storage_disable_shared_key.id
  display_name         = "${var.base_name} - ${data.azurerm_policy_definition.storage_disable_shared_key.display_name}"
  description          = data.azurerm_policy_definition.storage_disable_shared_key.description
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}