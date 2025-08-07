# Outputs

output "firewall_id" {
  description = "The resource ID of the Azure Firewall"
  value       = azurerm_firewall.main.id
}

output "firewall_name" {
  description = "The name of the Azure Firewall"
  value       = azurerm_firewall.main.name
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_policy_id" {
  description = "The resource ID of the Azure Firewall Policy"
  value       = azurerm_firewall_policy.main.id
}

output "firewall_policy_name" {
  description = "The name of the Azure Firewall Policy"
  value       = azurerm_firewall_policy.main.name
}

output "public_ip_egress_id" {
  description = "The resource ID of the firewall egress public IP"
  value       = azurerm_public_ip.firewall_egress.id
}

output "public_ip_egress_address" {
  description = "The IP address of the firewall egress public IP"
  value       = azurerm_public_ip.firewall_egress.ip_address
}

output "public_ip_management_id" {
  description = "The resource ID of the firewall management public IP"
  value       = azurerm_public_ip.firewall_management.id
}

output "public_ip_management_address" {
  description = "The IP address of the firewall management public IP"
  value       = azurerm_public_ip.firewall_management.ip_address
}