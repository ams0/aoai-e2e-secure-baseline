# Outputs

output "ai_foundry_name" {
  description = "The name of the Azure AI Foundry account."
  value       = azurerm_cognitive_account.ai_foundry.name
}

output "ai_foundry_id" {
  description = "The resource ID of the Azure AI Foundry account."
  value       = azurerm_cognitive_account.ai_foundry.id
}

output "ai_foundry_endpoint" {
  description = "The endpoint URL of the Azure AI Foundry account."
  value       = azurerm_cognitive_account.ai_foundry.endpoint
}

output "ai_foundry_primary_access_key" {
  description = "The primary access key of the Azure AI Foundry account."
  value       = azurerm_cognitive_account.ai_foundry.primary_access_key
  sensitive   = true
}

output "ai_foundry_secondary_access_key" {
  description = "The secondary access key of the Azure AI Foundry account."
  value       = azurerm_cognitive_account.ai_foundry.secondary_access_key
  sensitive   = true
}

output "ai_foundry_identity_principal_id" {
  description = "The principal ID of the Azure AI Foundry account's managed identity."
  value       = azurerm_cognitive_account.ai_foundry.identity[0].principal_id
}

output "ai_foundry_identity_tenant_id" {
  description = "The tenant ID of the Azure AI Foundry account's managed identity."
  value       = azurerm_cognitive_account.ai_foundry.identity[0].tenant_id
}

output "agent_model_id" {
  description = "The resource ID of the deployed agent model."
  value       = azurerm_cognitive_deployment.agent_model.id
}

output "private_endpoint_id" {
  description = "The resource ID of the AI Foundry private endpoint."
  value       = azurerm_private_endpoint.ai_foundry.id
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the AI Foundry private endpoint."
  value       = azurerm_private_endpoint.ai_foundry.private_service_connection[0].private_ip_address
}