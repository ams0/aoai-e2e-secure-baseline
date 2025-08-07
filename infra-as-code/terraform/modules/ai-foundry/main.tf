# Azure AI Foundry module - Deploy Azure AI Foundry with Azure AI Foundry Agent capability

locals {
  ai_foundry_name = "aif${var.base_name}"
}

# Get current resource group data
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Get current client configuration for role assignments
data "azurerm_client_config" "current" {}

# Existing resources

# Existing: Private DNS zone for Azure AI services using the cognitive services FQDN
data "azurerm_private_dns_zone" "cognitive_services" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Existing: Private DNS zone for Azure AI services using the Azure AI services FQDN
data "azurerm_private_dns_zone" "ai_foundry" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Existing: Private DNS zone for Azure AI services using the Azure AI OpenAI FQDN
data "azurerm_private_dns_zone" "azure_openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Existing: Built-in Cognitive Services User role
data "azurerm_role_definition" "cognitive_services_user" {
  name = "Cognitive Services User"
}

# Existing: Log sink for Azure Diagnostics
data "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# New resources

# Deploy Azure AI Foundry (account) with Foundry Agent Service capability
resource "azurerm_cognitive_account" "ai_foundry" {
  name                          = local.ai_foundry_name
  location                      = var.location
  resource_group_name          = data.azurerm_resource_group.main.name
  kind                         = "CognitiveServices"
  sku_name                     = "S0"
  custom_subdomain_name        = local.ai_foundry_name
  local_auth_enabled           = false
  public_network_access_enabled = false
  
  identity {
    type = "SystemAssigned"
  }
  
  network_acls {
    default_action = "Deny"
    ip_rules       = []
    virtual_network_rules {
      subnet_id = var.agent_subnet_id
    }
  }
  
  # Note: network_injections for agent scenario is not directly supported in azurerm provider
  # This will need to be configured via ARM template deployment or REST API calls
  
  tags = var.tags
}

# Deploy the GPT model that will be used for the Azure AI Foundry Agent logic
resource "azurerm_cognitive_deployment" "agent_model" {
  name                 = "agent-model"
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
  
  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20" # Use a model version available in your region
  }
  
  sku {
    name     = "Standard"
    capacity = 50
  }
  
  rai_policy_name          = "Microsoft.DefaultV2" # If this isn't strict enough for your use case, create a custom RAI policy
  version_upgrade_option   = "NoAutoUpgrade"       # Production deployments should not auto-upgrade models. Testing compatibility is important.
}

# Role assignments

# Assign the current user to have access to the Azure AI Foundry portal
resource "azurerm_role_assignment" "cognitive_services_user" {
  scope              = azurerm_cognitive_account.ai_foundry.id
  role_definition_id = data.azurerm_role_definition.cognitive_services_user.id
  principal_id       = var.ai_foundry_portal_user_principal_id
  principal_type     = "User"
}

# Private endpoints

# Connect the Azure AI Foundry account's endpoints to your existing private DNS zones
resource "azurerm_private_endpoint" "ai_foundry" {
  name                          = "pe-ai-foundry"
  location                      = var.location
  resource_group_name          = data.azurerm_resource_group.main.name
  subnet_id                    = var.private_endpoint_subnet_id
  custom_network_interface_name = "nic-ai-foundry"
  
  private_service_connection {
    name                           = "aifoundry"
    private_connection_resource_id = azurerm_cognitive_account.ai_foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name = "aifoundry"
    
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.ai_foundry.id,
      data.azurerm_private_dns_zone.azure_openai.id,
      data.azurerm_private_dns_zone.cognitive_services.id
    ]
  }
  
  tags = var.tags
  
  depends_on = [
    azurerm_cognitive_deployment.agent_model # Helps ensure the AI Foundry Account is stabilized before the private endpoint deployment is attempted
  ]
}

# Azure diagnostics

# Enable logging on the Azure AI Foundry account
resource "azurerm_monitor_diagnostic_setting" "ai_foundry" {
  name                       = "default"
  target_resource_id        = azurerm_cognitive_account.ai_foundry.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "Audit"
  }
  
  enabled_log {
    category = "RequestResponse"
  }
  
  enabled_log {
    category = "AzureOpenAIRequestUsage"
  }
  
  enabled_log {
    category = "Trace"
  }
}