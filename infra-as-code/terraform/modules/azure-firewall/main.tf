# Azure Firewall module for controlling egress traffic

# Get current resource group data
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Existing resources

data "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "agents_egress" {
  name                 = var.agents_egress_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "jump_boxes" {
  name                 = var.jump_boxes_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "firewall_management" {
  name                 = "AzureFirewallManagementSubnet"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_route_table" "egress" {
  name                = "udr-internet-to-firewall"
  resource_group_name = data.azurerm_resource_group.main.name
}

# New resources

# The public IP address for all traffic egressing from the firewall. 
# You can add more addresses if needed to reduce the chance for port exhaustion.
resource "azurerm_public_ip" "firewall_egress" {
  name                = "pip-firewall-egress-00"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  ip_version          = "IPv4"
  idle_timeout_in_minutes = 4
  
  tags = var.tags
}

# The public IP address for the Azure Firewall control plane.
resource "azurerm_public_ip" "firewall_management" {
  name                = "pip-firewall-mgmt-00"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  ip_version          = "IPv4"
  idle_timeout_in_minutes = 4
  
  tags = var.tags
}

# The firewall rules assigned to our egress firewall.
resource "azurerm_firewall_policy" "main" {
  name                = "fw-egress-policy"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Basic"
  threat_intelligence_mode = "Alert"
  
  tags = var.tags
}

# Network rules for the jump boxes subnet
resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 200

  network_rule_collection {
    name     = "jump-box-egress"
    priority = 1000
    action   = "Allow"
    
    rule {
      name                  = "allow-dependencies"
      protocols             = ["Any"]
      source_addresses      = [data.azurerm_subnet.jump_boxes.address_prefix]
      destination_addresses = ["*"] # Production readiness change: tighten destination address to ensure egress traffic is restricted to the minimal required spaces.
      destination_ports     = ["*"]
    }
  }
}

# Application rules for the Azure AI agent egress and jump boxes subnets
resource "azurerm_firewall_policy_rule_collection_group" "application_rules" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 300
  
  depends_on = [azurerm_firewall_policy_rule_collection_group.network_rules]

  application_rule_collection {
    name     = "agent-egress"
    priority = 1000
    action   = "Allow"
    
    rule {
      name             = "allow-dependencies"
      source_addresses = [data.azurerm_subnet.agents_egress.address_prefix]
      destination_fqdns = [
        "*"
        # "api.bing.microsoft.com" # Production readiness change: refine your target FQDNs to restrict egress traffic exclusively to the external services and endpoints your agent depends on. For instance this FQDN scopes access specifically to Grounding with Bing.
      ]
      
      protocols {
        type = "Https"
        port = 443
      }
    }
  }
  
  application_rule_collection {
    name     = "jump-box-egress"
    priority = 1100
    action   = "Allow"
    
    rule {
      name             = "allow-dependencies"
      source_addresses = [data.azurerm_subnet.jump_boxes.address_prefix]
      destination_fqdns = ["*"] # Production readiness change: specify target FQDNs to ensure only approved resources can be accessed from your jumpbox.
      
      protocols {
        type = "Https"
        port = 443
      }
      
      protocols {
        type = "Http"
        port = 80
      }
    }
  }
}

# Our workload's egress firewall. This is used to control outbound traffic from the workload to the Internet.
resource "azurerm_firewall" "main" {
  name                = "fw-egress"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  zones               = ["1", "2", "3"]
  threat_intel_mode   = "Alert"
  firewall_policy_id  = azurerm_firewall_policy.main.id
  
  management_ip_configuration {
    name                 = azurerm_public_ip.firewall_management.name
    subnet_id           = data.azurerm_subnet.firewall_management.id
    public_ip_address_id = azurerm_public_ip.firewall_management.id
  }
  
  ip_configuration {
    name                 = azurerm_public_ip.firewall_egress.name
    subnet_id           = data.azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_egress.id
  }
  
  tags = var.tags
  
  depends_on = [
    azurerm_firewall_policy_rule_collection_group.application_rules,
    azurerm_firewall_policy_rule_collection_group.network_rules
  ]
}

# Add route to direct internet traffic through the firewall
resource "azurerm_route" "internet_to_firewall" {
  name                   = "internet-to-firewall"
  resource_group_name    = data.azurerm_resource_group.main.name
  route_table_name       = data.azurerm_route_table.egress.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type         = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

# Azure diagnostics
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                           = "default"
  target_resource_id            = azurerm_firewall.main.id
  log_analytics_workspace_id    = data.azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }
  
  enabled_log {
    category = "AzureFirewallNetworkRule"
  }
  
  enabled_log {
    category = "AzureFirewallDnsProxy"
  }
  
  enabled_log {
    category = "AZFWNetworkRule"
  }
  
  enabled_log {
    category = "AZFWApplicationRule"
  }
  
  enabled_log {
    category = "AZFWNatRule"
  }
  
  enabled_log {
    category = "AZFWThreatIntel"
  }
  
  enabled_log {
    category = "AZFWIdpsSignature"
  }
  
  enabled_log {
    category = "AZFWDnsQuery"
  }
  
  enabled_log {
    category = "AZFWFqdnResolveFailure"
  }
  
  enabled_log {
    category = "AZFWFatFlow"
  }
  
  enabled_log {
    category = "AZFWFlowTrace"
  }
  
  enabled_log {
    category = "AZFWApplicationRuleAggregation"
  }
  
  enabled_log {
    category = "AZFWNetworkRuleAggregation"
  }
  
  enabled_log {
    category = "AZFWNatRuleAggregation"
  }
}