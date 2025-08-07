# AI Foundry Project module - Create AI Foundry project with connections to all dependent services

locals {
  project_name = "projchat"
}

# Get current resource group data
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Existing resources

# Get existing AI Foundry account
data "azurerm_cognitive_account" "ai_foundry" {
  name                = var.existing_ai_foundry_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get existing Cosmos DB account
data "azurerm_cosmosdb_account" "cosmos_db" {
  name                = var.existing_cosmos_db_account_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get existing Storage account
data "azurerm_storage_account" "agent_storage" {
  name                = var.existing_storage_account_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get existing AI Search service
data "azurerm_search_service" "ai_search" {
  name                = var.existing_ai_search_account_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get existing Application Insights
# Note: Temporarily commented out until Application Insights module is created
# data "azurerm_application_insights" "app_insights" {
#   name                = var.existing_web_application_insights_resource_name
#   resource_group_name = data.azurerm_resource_group.main.name
# }

# Built-in role definitions
data "azurerm_role_definition" "storage_blob_data_contributor" {
  name = "Storage Blob Data Contributor"
}

data "azurerm_role_definition" "storage_blob_data_owner" {
  name = "Storage Blob Data Owner"
}

data "azurerm_role_definition" "cosmos_db_operator" {
  name = "Cosmos DB Operator"
}

data "azurerm_role_definition" "search_service_contributor" {
  name = "Search Service Contributor"
}

data "azurerm_role_definition" "search_index_data_contributor" {
  name = "Search Index Data Contributor"
}

# New resources

# Create AI Foundry Project using ARM template deployment
# Note: AI Foundry projects are not directly supported in the AzureRM provider yet
resource "azurerm_resource_group_template_deployment" "ai_foundry_project" {
  name                = "ai-foundry-project-deployment"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  
  template_content = jsonencode({
    "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    "contentVersion" = "1.0.0.0"
    "parameters" = {
      "aiFoundryName" = {
        "type" = "string"
        "value" = var.existing_ai_foundry_name
      }
      "projectName" = {
        "type" = "string"
        "value" = local.project_name
      }
      "location" = {
        "type" = "string"
        "value" = var.location
      }
      "cosmosDbEndpoint" = {
        "type" = "string"
        "value" = data.azurerm_cosmosdb_account.cosmos_db.endpoint
      }
      "cosmosDbId" = {
        "type" = "string"
        "value" = data.azurerm_cosmosdb_account.cosmos_db.id
      }
      "storageEndpoint" = {
        "type" = "string"
        "value" = data.azurerm_storage_account.agent_storage.primary_blob_endpoint
      }
      "storageId" = {
        "type" = "string"
        "value" = data.azurerm_storage_account.agent_storage.id
      }
      "searchEndpoint" = {
        "type" = "string"
        "value" = "https://${data.azurerm_search_service.ai_search.name}.search.windows.net"
      }
      "searchId" = {
        "type" = "string"
        "value" = data.azurerm_search_service.ai_search.id
      }
      "appInsightsConnectionString" = {
        "type" = "string"
        "value" = "placeholder-connection-string"
      }
      "appInsightsId" = {
        "type" = "string"
        "value" = "placeholder-app-insights-id"
      }
      "tags" = {
        "type" = "object"
        "value" = var.tags
      }
    }
    "resources" = [
      {
        "type" = "Microsoft.CognitiveServices/accounts/projects"
        "apiVersion" = "2023-05-01"
        "name" = "[concat(parameters('aiFoundryName'), '/', parameters('projectName'))]"
        "location" = "[parameters('location')]"
        "identity" = {
          "type" = "SystemAssigned"
        }
        "properties" = {
          "description" = "Chat using internet data in your Azure AI Foundry Agent."
          "displayName" = "Chat with Internet Data"
        }
        "tags" = "[parameters('tags')]"
      },
      {
        "type" = "Microsoft.CognitiveServices/accounts/projects/connections"
        "apiVersion" = "2023-05-01"
        "name" = "[concat(parameters('aiFoundryName'), '/', parameters('projectName'), '/cosmos-connection')]"
        "properties" = {
          "authType" = "AAD"
          "category" = "CosmosDb"
          "target" = "[parameters('cosmosDbEndpoint')]"
          "metadata" = {
            "ApiType" = "Azure"
            "ResourceId" = "[parameters('cosmosDbId')]"
            "location" = "[parameters('location')]"
          }
        }
        "dependsOn" = [
          "[resourceId('Microsoft.CognitiveServices/accounts/projects', parameters('aiFoundryName'), parameters('projectName'))]"
        ]
      },
      {
        "type" = "Microsoft.CognitiveServices/accounts/projects/connections"
        "apiVersion" = "2023-05-01"
        "name" = "[concat(parameters('aiFoundryName'), '/', parameters('projectName'), '/storage-connection')]"
        "properties" = {
          "authType" = "AAD"
          "category" = "AzureStorageAccount"
          "target" = "[parameters('storageEndpoint')]"
          "metadata" = {
            "ApiType" = "Azure"
            "ResourceId" = "[parameters('storageId')]"
            "location" = "[parameters('location')]"
          }
        }
        "dependsOn" = [
          "[resourceId('Microsoft.CognitiveServices/accounts/projects/connections', parameters('aiFoundryName'), parameters('projectName'), 'cosmos-connection')]"
        ]
      },
      {
        "type" = "Microsoft.CognitiveServices/accounts/projects/connections"
        "apiVersion" = "2023-05-01"
        "name" = "[concat(parameters('aiFoundryName'), '/', parameters('projectName'), '/search-connection')]"
        "properties" = {
          "category" = "CognitiveSearch"
          "target" = "[parameters('searchEndpoint')]"
          "authType" = "AAD"
          "metadata" = {
            "ApiType" = "Azure"
            "ResourceId" = "[parameters('searchId')]"
            "location" = "[parameters('location')]"
          }
        }
        "dependsOn" = [
          "[resourceId('Microsoft.CognitiveServices/accounts/projects/connections', parameters('aiFoundryName'), parameters('projectName'), 'storage-connection')]"
        ]
      },
      {
        "type" = "Microsoft.CognitiveServices/accounts/projects/connections"
        "apiVersion" = "2023-05-01"
        "name" = "[concat(parameters('aiFoundryName'), '/', parameters('projectName'), '/appinsights-connection')]"
        "properties" = {
          "authType" = "ApiKey"
          "category" = "AppInsights"
          "credentials" = {
            "key" = "[parameters('appInsightsConnectionString')]"
          }
          "isSharedToAll" = false
          "target" = "[parameters('appInsightsId')]"
          "metadata" = {
            "ApiType" = "Azure"
            "ResourceId" = "[parameters('appInsightsId')]"
            "location" = "[parameters('location')]"
          }
        }
        "dependsOn" = [
          "[resourceId('Microsoft.CognitiveServices/accounts/projects/connections', parameters('aiFoundryName'), parameters('projectName'), 'search-connection')]"
        ]
      }
    ]
    "outputs" = {
      "projectName" = {
        "type" = "string"
        "value" = "[parameters('projectName')]"
      }
      "projectId" = {
        "type" = "string"
        "value" = "[resourceId('Microsoft.CognitiveServices/accounts/projects', parameters('aiFoundryName'), parameters('projectName'))]"
      }
      "projectPrincipalId" = {
        "type" = "string"
        "value" = "[reference(resourceId('Microsoft.CognitiveServices/accounts/projects', parameters('aiFoundryName'), parameters('projectName')), '2023-05-01', 'full').identity.principalId]"
      }
    }
  })
  
  depends_on = [
    azurerm_role_assignment.project_cosmos_operator,
    azurerm_role_assignment.project_blob_contributor,
    azurerm_role_assignment.project_blob_owner,
    azurerm_role_assignment.project_search_contributor,
    azurerm_role_assignment.project_search_index_contributor
  ]
}

# Role assignments for the AI Foundry project's managed identity
# Note: These need to be created first, but the principal ID is not available until after the project is created
# This creates a dependency issue that may require a two-step deployment or use of ARM template outputs

# Cosmos DB Operator role assignment
resource "azurerm_role_assignment" "project_cosmos_operator" {
  scope              = data.azurerm_cosmosdb_account.cosmos_db.id
  role_definition_id = data.azurerm_role_definition.cosmos_db_operator.id
  # Note: This will need to be updated with the actual principal ID after project creation
  # For now, using a placeholder that will be updated in a separate deployment
  principal_id   = "placeholder-will-be-updated"
  principal_type = "ServicePrincipal"
  
  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Storage Blob Data Contributor role assignment
resource "azurerm_role_assignment" "project_blob_contributor" {
  scope              = data.azurerm_storage_account.agent_storage.id
  role_definition_id = data.azurerm_role_definition.storage_blob_data_contributor.id
  principal_id       = "placeholder-will-be-updated"
  principal_type     = "ServicePrincipal"
  
  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Storage Blob Data Owner role assignment with condition
resource "azurerm_role_assignment" "project_blob_owner" {
  scope              = data.azurerm_storage_account.agent_storage.id
  role_definition_id = data.azurerm_role_definition.storage_blob_data_owner.id
  principal_id       = "placeholder-will-be-updated"
  principal_type     = "ServicePrincipal"
  condition_version  = "2.0"
  condition = "((!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/read'}) AND !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/filter/action'}) AND !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/write'})) OR (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringStartsWithIgnoreCase 'project-workspace'))"
  
  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Search Service Contributor role assignment
resource "azurerm_role_assignment" "project_search_contributor" {
  scope              = data.azurerm_search_service.ai_search.id
  role_definition_id = data.azurerm_role_definition.search_service_contributor.id
  principal_id       = "placeholder-will-be-updated"
  principal_type     = "ServicePrincipal"
  
  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Search Index Data Contributor role assignment
resource "azurerm_role_assignment" "project_search_index_contributor" {
  scope              = data.azurerm_search_service.ai_search.id
  role_definition_id = data.azurerm_role_definition.search_index_data_contributor.id
  principal_id       = "placeholder-will-be-updated"
  principal_type     = "ServicePrincipal"
  
  lifecycle {
    ignore_changes = [principal_id]
  }
}

# Cosmos DB SQL role assignments for specific database collections
# Note: These would typically be created using azurerm_cosmosdb_sql_role_assignment
# but require the project's internal ID which is only available after project creation