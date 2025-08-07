# Outputs

output "storage_account_name" {
  description = "The name of the agent storage account."
  value       = azurerm_storage_account.agent_storage.name
}

output "storage_account_id" {
  description = "The resource ID of the agent storage account."
  value       = azurerm_storage_account.agent_storage.id
}

output "cosmos_db_account_name" {
  description = "The name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.agent_cosmos.name
}

output "cosmos_db_account_id" {
  description = "The resource ID of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.agent_cosmos.id
}

output "ai_search_name" {
  description = "The name of the AI Search service."
  value       = azurerm_search_service.agent_search.name
}

output "ai_search_id" {
  description = "The resource ID of the AI Search service."
  value       = azurerm_search_service.agent_search.id
}

output "storage_private_endpoint_id" {
  description = "The resource ID of the storage private endpoint."
  value       = azurerm_private_endpoint.agent_storage.id
}

output "cosmos_private_endpoint_id" {
  description = "The resource ID of the Cosmos DB private endpoint."
  value       = azurerm_private_endpoint.agent_cosmos.id
}

output "search_private_endpoint_id" {
  description = "The resource ID of the AI Search private endpoint."
  value       = azurerm_private_endpoint.agent_search.id
}