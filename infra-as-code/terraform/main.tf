# Get current resource group data
data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

locals {
  # Customer Usage Attribution Id
  cua_id = var.cua_id
  
  # Common tags
  common_tags = {
    Environment = "secure-baseline"
    Project     = "aoai-e2e"
    ManagedBy   = "terraform"
  }
}

# Deploy Azure Policies to help govern the workload
module "azure_policies" {
  source = "./modules/azure-policies"
  
  resource_group_name = data.azurerm_resource_group.main.name
  base_name          = var.base_name
  
  tags = local.common_tags
}

# Log Analytics workspace - the log sink for all Azure Diagnostics in the workload
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-workload"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 10 # Production readiness change: In production, tune this value to ensure operational logs are collected, but a reasonable cap is set.
  
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  
  tags = local.common_tags
}

# Deploy Virtual Network with subnets, NSGs, and DDoS Protection
module "virtual_network" {
  source = "./modules/network"
  
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = local.common_tags
}

# Control egress traffic through Azure Firewall restrictions
module "azure_firewall" {
  source = "./modules/azure-firewall"
  
  location                       = var.location
  resource_group_name           = data.azurerm_resource_group.main.name
  log_analytics_workspace_name = azurerm_log_analytics_workspace.main.name
  virtual_network_name          = module.virtual_network.virtual_network_name
  agents_egress_subnet_name     = module.virtual_network.agents_egress_subnet_name
  jump_boxes_subnet_name        = module.virtual_network.jump_boxes_subnet_name
  
  tags = local.common_tags
  
  depends_on = [
    module.virtual_network
  ]
}

# Commented out modules to match the Bicep structure for incremental deployment
# Uncomment these as you progress through the deployment phases

module "jump_box" {
  source = "./modules/jump-box"
  
  location                       = var.location
  resource_group_name           = data.azurerm_resource_group.main.name
  base_name                     = var.base_name
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.main.id
  virtual_network_name          = module.virtual_network.virtual_network_name
  jump_box_subnet_name          = module.virtual_network.jump_boxes_subnet_name
  jump_box_admin_name           = "vmadmin"
  jump_box_admin_password       = var.jump_box_admin_password
  
  tags = local.common_tags
  
  depends_on = [
    module.azure_firewall  # Makes sure that egress traffic is controlled before workload resources start being deployed
  ]
}

module "ai_foundry" {
  source = "./modules/ai-foundry"
  
  location                            = var.location
  resource_group_name                = data.azurerm_resource_group.main.name
  base_name                          = var.base_name
  log_analytics_workspace_name       = azurerm_log_analytics_workspace.main.name
  agent_subnet_id                    = module.virtual_network.agents_egress_subnet_id
  private_endpoint_subnet_id         = module.virtual_network.private_endpoints_subnet_id
  ai_foundry_portal_user_principal_id = data.azurerm_client_config.current.object_id
  
  tags = local.common_tags
  
  depends_on = [
    module.azure_firewall  # Makes sure that egress traffic is controlled before workload resources start being deployed
  ]
}

module "ai_agent_service_dependencies" {
  source = "./modules/ai-agent-service-dependencies"
  
  location                       = var.location
  resource_group_name           = data.azurerm_resource_group.main.name
  base_name                     = var.base_name
  log_analytics_workspace_name  = azurerm_log_analytics_workspace.main.name
  debug_user_principal_id       = data.azurerm_client_config.current.object_id
  private_endpoint_subnet_id    = module.virtual_network.private_endpoints_subnet_id
  
  tags = local.common_tags
  
  depends_on = [
    module.ai_foundry  # AI Agent Service Dependencies need the AI Foundry to be deployed first
  ]
}

module "bing_grounding" {
  source = "./modules/bing-grounding"
  
  resource_group_name = data.azurerm_resource_group.main.name
  base_name          = var.base_name
  
  tags = local.common_tags
}

module "ai_foundry_project" {
  source = "./modules/ai-foundry-project"
  
  location                                    = var.location
  resource_group_name                        = data.azurerm_resource_group.main.name
  existing_ai_foundry_name                   = module.ai_foundry.ai_foundry_name
  existing_ai_search_account_name            = module.ai_agent_service_dependencies.ai_search_name
  existing_cosmos_db_account_name            = module.ai_agent_service_dependencies.cosmos_db_account_name
  existing_storage_account_name              = module.ai_agent_service_dependencies.storage_account_name
  existing_bing_account_name                 = module.bing_grounding.bing_account_name
  existing_web_application_insights_resource_name = "placeholder-app-insights" # Will be updated when application_insights module is created
  
  tags = local.common_tags
  
  depends_on = [
    module.jump_box,
    module.ai_agent_service_dependencies,
    module.bing_grounding
  ]
}

# module "web_app_storage" {
#   source = "./modules/web-app-storage"
#   
#   location                       = var.location
#   resource_group_name           = data.azurerm_resource_group.main.name
#   base_name                     = var.base_name
#   log_analytics_workspace_id    = azurerm_log_analytics_workspace.main.id
#   virtual_network_name          = module.virtual_network.virtual_network_name
#   private_endpoints_subnet_name = module.virtual_network.private_endpoints_subnet_name
#   debug_user_principal_id       = data.azurerm_client_config.current.object_id
#   
#   tags = local.common_tags
#   
#   depends_on = [
#     module.ai_agent_service_dependencies  # There is a Storage account in the AI Agent dependencies module, both will be updating the same private DNS zone, want to run them in series to avoid conflict errors.
#   ]
# }

# module "key_vault" {
#   source = "./modules/key-vault"
#   
#   location                            = var.location
#   resource_group_name                = data.azurerm_resource_group.main.name
#   base_name                          = var.base_name
#   log_analytics_workspace_id         = azurerm_log_analytics_workspace.main.id
#   virtual_network_name               = module.virtual_network.virtual_network_name
#   private_endpoints_subnet_name      = module.virtual_network.private_endpoints_subnet_name
#   app_gateway_listener_certificate   = var.app_gateway_listener_certificate
#   
#   tags = local.common_tags
# }

# module "application_insights" {
#   source = "./modules/application-insights"
#   
#   location                       = var.location
#   resource_group_name           = data.azurerm_resource_group.main.name
#   base_name                     = var.base_name
#   log_analytics_workspace_id    = azurerm_log_analytics_workspace.main.id
#   
#   tags = local.common_tags
# }

# module "web_app" {
#   source = "./modules/web-app"
#   
#   location                                         = var.location
#   resource_group_name                             = data.azurerm_resource_group.main.name
#   base_name                                       = var.base_name
#   log_analytics_workspace_id                      = azurerm_log_analytics_workspace.main.id
#   publish_file_name                               = var.publish_file_name
#   virtual_network_name                            = module.virtual_network.virtual_network_name
#   app_services_subnet_name                        = module.virtual_network.app_services_subnet_name
#   private_endpoints_subnet_name                   = module.virtual_network.private_endpoints_subnet_name
#   existing_web_app_deployment_storage_account_name = module.web_app_storage.app_deploy_storage_name
#   existing_web_application_insights_resource_name = module.application_insights.application_insights_name
#   existing_azure_ai_foundry_resource_name         = module.ai_foundry.ai_foundry_name
#   existing_azure_ai_foundry_project_name          = module.ai_foundry_project.ai_agent_project_name
#   
#   tags = local.common_tags
# }

# module "application_gateway" {
#   source = "./modules/application-gateway"
#   
#   location                         = var.location
#   resource_group_name             = data.azurerm_resource_group.main.name
#   base_name                       = var.base_name
#   log_analytics_workspace_id      = azurerm_log_analytics_workspace.main.id
#   custom_domain_name              = var.custom_domain_name
#   app_name                        = module.web_app.app_name
#   virtual_network_name            = module.virtual_network.virtual_network_name
#   application_gateway_subnet_name = module.virtual_network.application_gateway_subnet_name
#   key_vault_name                  = module.key_vault.key_vault_name
#   gateway_cert_secret_key         = module.key_vault.gateway_cert_secret_key
#   
#   tags = local.common_tags
# }

# Optional Deployment for Customer Usage Attribution
# resource "azurerm_resource_group_template_deployment" "cua" {
#   count               = var.telemetry_opt_out ? 0 : 1
#   name                = "pid-${local.cua_id}-${substr(sha256(var.location), 0, 13)}"
#   resource_group_name = data.azurerm_resource_group.main.name
#   deployment_mode     = "Incremental"
#   template_content    = "{\"$schema\": \"https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#\", \"contentVersion\": \"1.0.0.0\", \"parameters\": {}, \"variables\": {}, \"resources\": [], \"outputs\": {}}"
# }