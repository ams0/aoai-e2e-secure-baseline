# Network Security Groups for subnets

# NSG for App Service subnet
resource "azurerm_network_security_group" "app_service" {
  name                = "nsg-appServicesSubnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  security_rule {
    name                       = "AppPlan.Out.Allow.PrivateEndpoints"
    description                = "Allow outbound traffic from the app service subnet to the private endpoints subnet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = local.app_services_subnet_prefix
    destination_address_prefix = local.private_endpoints_subnet_prefix
  }
  
  security_rule {
    name                       = "AppPlan.Out.Allow.AzureMonitor"
    description                = "Allow outbound traffic from App service to the AzureMonitor ServiceTag."
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.app_services_subnet_prefix
    destination_address_prefix = "AzureMonitor"
  }
  
  tags = var.tags
}

# NSG for Private Endpoints subnet
resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-privateEndpointsSubnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  security_rule {
    name                       = "DenyAllOutBound"
    description                = "Deny outbound traffic from the private endpoints subnet"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.private_endpoints_subnet_prefix
    destination_address_prefix = "*"
  }
  
  tags = var.tags
}

# NSG for Build Agents subnet
resource "azurerm_network_security_group" "build_agents" {
  name                = "nsg-buildAgentsSubnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  security_rule {
    name                       = "DenyAllOutBound"
    description                = "Deny outbound traffic from the build agents subnet. Note: adjust rules as needed based on the resources added to the subnet"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.build_agents_subnet_prefix
    destination_address_prefix = "*"
  }
  
  tags = var.tags
}

# NSG for Azure AI Foundry Agent Service egress subnet
resource "azurerm_network_security_group" "agents_egress" {
  name                = "nsg-agentsEgressSubnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
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
    name                       = "Agents.Out.Allow.PrivateEndpoints"
    description                = "Allow outbound traffic from the Azure AI Foundry Agent egress subnet to the Private Endpoints subnet."
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.ai_agents_egress_subnet_prefix
    destination_address_prefix = local.private_endpoints_subnet_prefix
  }
  
  security_rule {
    name                       = "Agents.Out.AllowTcp443.Internet"
    description                = "Allow outbound traffic from the Azure AI Foundry Agent egress subnet to Internet on 443 (Azure firewall to filter further)"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = local.ai_agents_egress_subnet_prefix
    destination_address_prefix = "Internet"
  }
  
  security_rule {
    name                       = "DenyAllOutBound"
    description                = "Deny all other outbound traffic from the Azure AI Foundry Agent subnet."
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.ai_agents_egress_subnet_prefix
    destination_address_prefix = "*"
  }
  
  tags = var.tags
}

# Bastion host subnet NSG
# https://learn.microsoft.com/azure/bastion/bastion-nsg
# https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.network/azure-bastion-nsg/main.bicep
resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-bastionSubnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  security_rule {
    name                       = "Bastion.In.Allow.Https"
    description                = "Allow inbound Https traffic from the from the Internet to the Bastion Host"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_port_range     = "443"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                         = "Bastion.In.Allow.GatewayManager"
    priority                     = 110
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    source_address_prefix        = "GatewayManager"
    destination_port_ranges      = ["443", "4443"]
    destination_address_prefix   = "*"
  }
  
  security_rule {
    name                       = "Bastion.In.Allow.LoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_port_range     = "443"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                         = "Bastion.In.Allow.BastionHostCommunication"
    priority                     = 130
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    source_address_prefix        = "VirtualNetwork"
    destination_port_ranges      = ["8080", "5701"]
    destination_address_prefix   = "VirtualNetwork"
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
    name                         = "Bastion.Out.Allow.SshRdp"
    description                  = "Allow outbound RDP and SSH from the Bastion Host subnet to elsewhere in the vnet"
    priority                     = 100
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    source_address_prefix        = "*"
    destination_port_ranges      = ["22", "3389"]
    destination_address_prefix   = "VirtualNetwork"
  }
  
  security_rule {
    name                       = "Bastion.Out.Allow.AzureMonitor"
    description                = "Allow outbound traffic from the Bastion Host subnet to Azure Monitor"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.bastion_subnet_prefix
    destination_address_prefix = "AzureMonitor"
  }
  
  security_rule {
    name                       = "Bastion.Out.Allow.AzureCloudCommunication"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = "AzureCloud"
  }
  
  security_rule {
    name                         = "Bastion.Out.Allow.BastionHostCommunication"
    priority                     = 130
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    source_address_prefix        = "VirtualNetwork"
    destination_port_ranges      = ["8080", "5701"]
    destination_address_prefix   = "VirtualNetwork"
  }
  
  security_rule {
    name                         = "Bastion.Out.Allow.GetSessionInformation"
    priority                     = 140
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    source_address_prefix        = "*"
    destination_address_prefix   = "Internet"
    destination_port_ranges      = ["80", "443"]
  }
  
  security_rule {
    name                       = "DenyAllOutBound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = var.tags
}

# NSG for Jump Box subnet
resource "azurerm_network_security_group" "jump_box" {
  name                = "nsg-jumpBoxesSubnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  security_rule {
    name                         = "JumpBox.In.Allow.SshRdp"
    description                  = "Allow inbound RDP and SSH from the Bastion Host subnet"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    source_address_prefix        = local.bastion_subnet_prefix
    destination_port_ranges      = ["22", "3389"]
    destination_address_prefix   = local.jump_box_subnet_prefix
  }
  
  security_rule {
    name                       = "JumpBox.Out.Allow.PrivateEndpoints"
    description                = "Allow outbound traffic from the jump box subnet to the Private Endpoints subnet."
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.jump_box_subnet_prefix
    destination_address_prefix = local.private_endpoints_subnet_prefix
  }
  
  security_rule {
    name                       = "JumpBox.Out.Allow.Internet"
    description                = "Allow outbound traffic from all VMs to Internet"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.jump_box_subnet_prefix
    destination_address_prefix = "Internet"
  }
  
  security_rule {
    name                       = "DenyAllOutBound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.jump_box_subnet_prefix
    destination_address_prefix = "*"
  }
  
  tags = var.tags
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                 = azurerm_subnet.app_service_plan.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

resource "azurerm_subnet_network_security_group_association" "build_agents" {
  subnet_id                 = azurerm_subnet.build_agents.id
  network_security_group_id = azurerm_network_security_group.build_agents.id
}

resource "azurerm_subnet_network_security_group_association" "agents_egress" {
  subnet_id                 = azurerm_subnet.agents_egress.id
  network_security_group_id = azurerm_network_security_group.agents_egress.id
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_subnet_network_security_group_association" "jump_box" {
  subnet_id                 = azurerm_subnet.jump_boxes.id
  network_security_group_id = azurerm_network_security_group.jump_box.id
}

# Associate route table with subnets that need controlled egress
resource "azurerm_subnet_route_table_association" "private_endpoints" {
  subnet_id      = azurerm_subnet.private_endpoints.id
  route_table_id = azurerm_route_table.egress.id
}

resource "azurerm_subnet_route_table_association" "build_agents" {
  subnet_id      = azurerm_subnet.build_agents.id
  route_table_id = azurerm_route_table.egress.id
}

resource "azurerm_subnet_route_table_association" "jump_boxes" {
  subnet_id      = azurerm_subnet.jump_boxes.id
  route_table_id = azurerm_route_table.egress.id
}

resource "azurerm_subnet_route_table_association" "agents_egress" {
  subnet_id      = azurerm_subnet.agents_egress.id
  route_table_id = azurerm_route_table.egress.id
}