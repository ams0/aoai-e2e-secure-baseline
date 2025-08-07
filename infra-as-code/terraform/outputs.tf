# Main deployment outputs

output "resource_group_name" {
  description = "The name of the resource group where resources are deployed"
  value       = data.azurerm_resource_group.main.name
}

output "location" {
  description = "The location where resources are deployed"
  value       = var.location
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = module.virtual_network.virtual_network_name
}

output "virtual_network_id" {
  description = "The resource ID of the virtual network"
  value       = module.virtual_network.virtual_network_id
}

# Subnet outputs
output "app_services_subnet_name" {
  description = "The name of the app services subnet"
  value       = module.virtual_network.app_services_subnet_name
}

output "application_gateway_subnet_name" {
  description = "The name of the application gateway subnet"
  value       = module.virtual_network.application_gateway_subnet_name
}

output "private_endpoints_subnet_name" {
  description = "The name of the private endpoints subnet"
  value       = module.virtual_network.private_endpoints_subnet_name
}

output "agents_egress_subnet_name" {
  description = "The name of the agents egress subnet"
  value       = module.virtual_network.agents_egress_subnet_name
}

output "agents_egress_subnet_id" {
  description = "The resource ID of the agents egress subnet"
  value       = module.virtual_network.agents_egress_subnet_id
}

output "private_endpoints_subnet_id" {
  description = "The resource ID of the private endpoints subnet"
  value       = module.virtual_network.private_endpoints_subnet_id
}

output "jump_boxes_subnet_name" {
  description = "The name of the jump boxes subnet"
  value       = module.virtual_network.jump_boxes_subnet_name
}