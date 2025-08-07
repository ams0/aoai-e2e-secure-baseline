# Outputs

output "ai_agent_project_name" {
  description = "The name of the AI Foundry project."
  value       = jsondecode(azurerm_resource_group_template_deployment.ai_foundry_project.output_content).projectName.value
}

output "ai_agent_project_id" {
  description = "The resource ID of the AI Foundry project."
  value       = jsondecode(azurerm_resource_group_template_deployment.ai_foundry_project.output_content).projectId.value
}

output "ai_agent_project_principal_id" {
  description = "The principal ID of the AI Foundry project's managed identity."
  value       = jsondecode(azurerm_resource_group_template_deployment.ai_foundry_project.output_content).projectPrincipalId.value
}