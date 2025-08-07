# Outputs

output "bing_account_name" {
  description = "The name of the Bing Search account."
  value       = local.bing_account_name
}

output "bing_account_id" {
  description = "The resource ID of the Bing Search account."
  value       = jsondecode(azurerm_resource_group_template_deployment.bing_grounding.output_content).accountId.value
}