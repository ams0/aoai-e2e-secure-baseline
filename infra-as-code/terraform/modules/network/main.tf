# Establish the private network for the workload

# Azure AI Foundry Agent Service currently has a limitation on subnet prefixes.
# 10.x was not supported, as such 192.168.x.x was used.
locals {
  virtual_network_address_prefix         = "192.168.0.0/16"
  app_gateway_subnet_prefix             = "192.168.1.0/24"
  app_services_subnet_prefix            = "192.168.0.0/24"
  private_endpoints_subnet_prefix       = "192.168.2.0/27"
  build_agents_subnet_prefix            = "192.168.2.32/27"
  bastion_subnet_prefix                 = "192.168.2.64/26"
  jump_box_subnet_prefix                = "192.168.2.128/28"
  ai_agents_egress_subnet_prefix        = "192.168.3.0/24"
  azure_firewall_subnet_prefix          = "192.168.4.0/26"
  azure_firewall_management_subnet_prefix = "192.168.4.64/26"
  
  enable_ddos_protection = false # Production readiness change: protect your public IPs in this architecture with DDoS protection by setting this to true.
}

# Get current resource group data
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# DDoS Protection Plan
# Cost optimization: DDoS protection plans are relatively expensive. If deploying this as part of
# a POC and your environment can be down during a targeted DDoS attack, consider not deploying
# this resource by setting `enable_ddos_protection` to false.
resource "azurerm_network_ddos_protection_plan" "main" {
  count               = local.enable_ddos_protection ? 1 : 0
  name                = "ddos-workload"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

# Placeholder route table for egress traffic from subnets that we want to control routing for. 
# When the firewall is created, the routes will be added.
resource "azurerm_route_table" "egress" {
  name                = "udr-internet-to-firewall"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

# Virtual Network for the workload. Contains subnets for App Gateway, App Service Plan, Private Endpoints, 
# Build Agents, Bastion Host, Jump Box, and Azure AI Foundry Agents Service.
resource "azurerm_virtual_network" "main" {
  name                = "vnet-workload"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = [local.virtual_network_address_prefix]
  
  dynamic "ddos_protection_plan" {
    for_each = local.enable_ddos_protection ? [1] : []
    content {
      id     = azurerm_network_ddos_protection_plan.main[0].id
      enable = true
    }
  }
  
  tags = var.tags
}

# App services plan subnet
resource "azurerm_subnet" "app_service_plan" {
  name                 = "snet-appServicePlan"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.app_services_subnet_prefix]
  
  delegation {
    name = "delegation"
    
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# App Gateway subnet
resource "azurerm_subnet" "app_gateway" {
  name                 = "snet-appGateway"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.app_gateway_subnet_prefix]
  
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

# Private endpoints subnet
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-privateEndpoints"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.private_endpoints_subnet_prefix]
  
  private_endpoint_network_policies             = "Enabled" # Route Table and NSGs
  private_link_service_network_policies_enabled = true
  default_outbound_access_enabled               = false # This subnet should never be the source of egress traffic.
}

# Build agents subnet
resource "azurerm_subnet" "build_agents" {
  name                 = "snet-buildAgents"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.build_agents_subnet_prefix]
  
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  default_outbound_access_enabled               = false # Force your build agent traffic through your firewall.
}

# Azure Bastion subnet
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.bastion_subnet_prefix]
  
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  default_outbound_access_enabled               = false
}

# Jump box virtual machine subnet
resource "azurerm_subnet" "jump_boxes" {
  name                 = "snet-jumpBoxes"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.jump_box_subnet_prefix]
  
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  default_outbound_access_enabled               = false # Force agent traffic through your firewall.
}

# Azure AI Foundry Agent Service subnet for egress traffic
resource "azurerm_subnet" "agents_egress" {
  name                 = "snet-agentsEgress"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.ai_agents_egress_subnet_prefix]
  service_endpoints    = ["Microsoft.CognitiveServices"]

  
  delegation {
    name = "Microsoft.App/environments"
    
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
  
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  default_outbound_access_enabled               = false # Force agent traffic through your firewall.
}

# Workload firewall for all egress traffic
resource "azurerm_subnet" "azure_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.azure_firewall_subnet_prefix]
  
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

# Workload firewall management subnet
resource "azurerm_subnet" "azure_firewall_management" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.azure_firewall_management_subnet_prefix]
  
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
}

# Network Security Groups and associations will be in separate files
# NSG for App Gateway subnet
resource "azurerm_network_security_group" "app_gateway" {
  name                = "nsg-appGatewaySubnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  security_rule {
    name                       = "AppGw.In.Allow.ControlPlane"
    description                = "Allow inbound Control Plane (https://docs.microsoft.com/azure/application-gateway/configuration-infrastructure#network-security-groups)"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "AppGw.In.Allow443.Internet"
    description                = "Allow ALL inbound web traffic on port 443"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = local.app_gateway_subnet_prefix
  }
  
  security_rule {
    name                       = "AppGw.In.Allow.LoadBalancer"
    description                = "Allow inbound traffic from azure load balancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "DenyAllInBound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "AppGw.Out.Allow.PrivateEndpoints"
    description                = "Allow outbound traffic from the App Gateway subnet to the Private Endpoints subnet."
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.app_gateway_subnet_prefix
    destination_address_prefix = local.private_endpoints_subnet_prefix
  }
  
  security_rule {
    name                       = "AppPlan.Out.Allow.AzureMonitor"
    description                = "Allow outbound traffic from the App Gateway subnet to Azure Monitor"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.app_gateway_subnet_prefix
    destination_address_prefix = "AzureMonitor"
  }
  
  tags = var.tags
}

# Associate NSG with App Gateway subnet
resource "azurerm_subnet_network_security_group_association" "app_gateway" {
  subnet_id                 = azurerm_subnet.app_gateway.id
  network_security_group_id = azurerm_network_security_group.app_gateway.id
}