# Outputs

output "virtual_network_name" {
  description = "The name of the virtual network."
  value       = azurerm_virtual_network.main.name
}

output "app_services_subnet_name" {
  description = "The name of the app service plan subnet."
  value       = azurerm_subnet.app_service_plan.name
}

output "application_gateway_subnet_name" {
  description = "The name of the Azure Application Gateway subnet."
  value       = azurerm_subnet.app_gateway.name
}

output "private_endpoints_subnet_name" {
  description = "The name of the private endpoints subnet."
  value       = azurerm_subnet.private_endpoints.name
}

output "jump_boxes_subnet_name" {
  description = "The name of the jump boxes subnet."
  value       = azurerm_subnet.jump_boxes.name
}

output "build_agents_subnet_name" {
  description = "The name of the build agents subnet."
  value       = azurerm_subnet.build_agents.name
}

output "agents_egress_subnet_name" {
  description = "The name of the Azure AI Foundry Agents egress subnet."
  value       = azurerm_subnet.agents_egress.name
}

output "agents_egress_subnet_id" {
  description = "The resource ID of the Azure AI Foundry Agents egress subnet."
  value       = azurerm_subnet.agents_egress.id
}

output "private_endpoints_subnet_id" {
  description = "The resource ID of the private endpoints subnet."
  value       = azurerm_subnet.private_endpoints.id
}

output "jump_box_subnet_name" {
  description = "The name of the subnet for jump boxes."
  value       = azurerm_subnet.jump_boxes.name
}

# Additional subnet IDs for use by other modules
output "app_services_subnet_id" {
  description = "The resource ID of the app service plan subnet."
  value       = azurerm_subnet.app_service_plan.id
}

output "application_gateway_subnet_id" {
  description = "The resource ID of the Azure Application Gateway subnet."
  value       = azurerm_subnet.app_gateway.id
}

output "build_agents_subnet_id" {
  description = "The resource ID of the build agents subnet."
  value       = azurerm_subnet.build_agents.id
}

output "jump_boxes_subnet_id" {
  description = "The resource ID of the jump boxes subnet."
  value       = azurerm_subnet.jump_boxes.id
}

output "bastion_subnet_id" {
  description = "The resource ID of the bastion subnet."
  value       = azurerm_subnet.bastion.id
}

output "azure_firewall_subnet_id" {
  description = "The resource ID of the Azure Firewall subnet."
  value       = azurerm_subnet.azure_firewall.id
}

output "azure_firewall_management_subnet_id" {
  description = "The resource ID of the Azure Firewall Management subnet."
  value       = azurerm_subnet.azure_firewall_management.id
}

output "virtual_network_id" {
  description = "The resource ID of the virtual network."
  value       = azurerm_virtual_network.main.id
}

output "egress_route_table_id" {
  description = "The resource ID of the egress route table."
  value       = azurerm_route_table.egress.id
}

# Private DNS Zone outputs for use by other modules
output "cognitive_services_private_dns_zone_id" {
  description = "The resource ID of the cognitive services private DNS zone."
  value       = azurerm_private_dns_zone.cognitive_services.id
}

output "ai_foundry_private_dns_zone_id" {
  description = "The resource ID of the AI Foundry private DNS zone."
  value       = azurerm_private_dns_zone.ai_foundry.id
}

output "azure_openai_private_dns_zone_id" {
  description = "The resource ID of the Azure OpenAI private DNS zone."
  value       = azurerm_private_dns_zone.azure_openai.id
}

output "ai_search_private_dns_zone_id" {
  description = "The resource ID of the AI Search private DNS zone."
  value       = azurerm_private_dns_zone.ai_search.id
}

output "blob_storage_private_dns_zone_id" {
  description = "The resource ID of the blob storage private DNS zone."
  value       = azurerm_private_dns_zone.blob_storage.id
}

output "cosmos_db_private_dns_zone_id" {
  description = "The resource ID of the Cosmos DB private DNS zone."
  value       = azurerm_private_dns_zone.cosmos_db.id
}

output "key_vault_private_dns_zone_id" {
  description = "The resource ID of the Key Vault private DNS zone."
  value       = azurerm_private_dns_zone.key_vault.id
}

output "app_service_private_dns_zone_id" {
  description = "The resource ID of the App Service private DNS zone."
  value       = azurerm_private_dns_zone.app_service.id
}