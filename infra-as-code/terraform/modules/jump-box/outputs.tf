# Outputs

output "bastion_host_name" {
  description = "The name of the Azure Bastion host."
  value       = azurerm_bastion_host.main.name
}

output "bastion_host_id" {
  description = "The resource ID of the Azure Bastion host."
  value       = azurerm_bastion_host.main.id
}

output "bastion_host_fqdn" {
  description = "The FQDN of the Azure Bastion host."
  value       = azurerm_public_ip.bastion.fqdn
}

output "jump_box_vm_name" {
  description = "The name of the jump box virtual machine."
  value       = azurerm_windows_virtual_machine.jump_box.name
}

output "jump_box_vm_id" {
  description = "The resource ID of the jump box virtual machine."
  value       = azurerm_windows_virtual_machine.jump_box.id
}

output "jump_box_computer_name" {
  description = "The computer name of the jump box virtual machine."
  value       = azurerm_windows_virtual_machine.jump_box.computer_name
}

output "jump_box_private_ip" {
  description = "The private IP address of the jump box virtual machine."
  value       = azurerm_network_interface.jump_box.private_ip_address
}

output "data_collection_rule_id" {
  description = "The resource ID of the VM Insights data collection rule."
  value       = azurerm_monitor_data_collection_rule.vm_insights.id
}

output "public_ip_address" {
  description = "The public IP address of the Azure Bastion host."
  value       = azurerm_public_ip.bastion.ip_address
}