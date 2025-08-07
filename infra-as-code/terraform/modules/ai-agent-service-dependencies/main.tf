# AI Agent Service Dependencies module - Deploy Storage, Cosmos DB, and AI Search dependencies

locals {
  storage_account_name = "stagent${var.base_name}"
  cosmos_db_name      = "cdb-ai-agent-threads-${var.base_name}"
  ai_search_name      = "ais-ai-agent-vector-store-${var.base_name}"
}

# Get current resource group data
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Existing resources

# Existing: Private DNS zones
data "azurerm_private_dns_zone" "blob_storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_private_dns_zone" "cosmos_db" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_private_dns_zone" "ai_search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Existing: Built-in role definitions
data "azurerm_role_definition" "storage_blob_data_owner" {
  name = "Storage Blob Data Owner"
}

data "azurerm_role_definition" "cosmos_db_account_reader" {
  name = "Cosmos DB Account Reader Role"
}

data "azurerm_role_definition" "search_index_data_contributor" {
  name = "Search Index Data Contributor"
}

# Existing: Log Analytics workspace
data "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# New resources

# Deploy Azure Storage account for the Azure AI Foundry Agent Service
resource "azurerm_storage_account" "agent_storage" {
  name                     = local.storage_account_name
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GZRS"
  account_kind             = "StorageV2"
  
  access_tier                       = "Hot"
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  public_network_access_enabled     = false
  default_to_oauth_authentication   = true
  cross_tenant_replication_enabled  = false
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
  
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
  
  tags = var.tags
}

# Deploy Azure Cosmos DB account for storing threads and agent definitions
resource "azurerm_cosmosdb_account" "agent_cosmos" {
  name                = local.cosmos_db_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  
  consistency_policy {
    consistency_level = "Session"
  }
  
  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }
  
  local_authentication_disabled         = true
  public_network_access_enabled        = false
  is_virtual_network_filter_enabled    = true
  ip_range_filter                      = []
  multiple_write_locations_enabled     = false
  automatic_failover_enabled           = false
  
  backup {
    type                = "Continuous"
    tier               = "Continuous7Days"
    interval_in_minutes = 240
    retention_in_hours  = 168
    storage_redundancy  = "Geo"
  }
  
  tags = var.tags
}

# Deploy Azure AI Search instance for vector search capabilities
resource "azurerm_search_service" "agent_search" {
  name                = local.ai_search_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  sku                 = "standard"
  
  replica_count                = 3
  partition_count             = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false
  authentication_failure_mode   = null
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Role assignments

# Assign debug user to Storage Blob Data Owner role
resource "azurerm_role_assignment" "debug_user_blob_owner" {
  scope              = azurerm_storage_account.agent_storage.id
  role_definition_id = data.azurerm_role_definition.storage_blob_data_owner.id
  principal_id       = var.debug_user_principal_id
  principal_type     = "User"
}

# Assign debug user to Cosmos DB Account Reader role
resource "azurerm_role_assignment" "debug_user_cosmos_reader" {
  scope              = azurerm_cosmosdb_account.agent_cosmos.id
  role_definition_id = data.azurerm_role_definition.cosmos_db_account_reader.id
  principal_id       = var.debug_user_principal_id
  principal_type     = "User"
}

# Assign debug user to Search Index Data Contributor role
resource "azurerm_role_assignment" "debug_user_search_contributor" {
  scope              = azurerm_search_service.agent_search.id
  role_definition_id = data.azurerm_role_definition.search_index_data_contributor.id
  principal_id       = var.debug_user_principal_id
  principal_type     = "User"
}

# Cosmos DB Data Contributor role assignment for debug user
resource "azurerm_cosmosdb_sql_role_assignment" "debug_user_cosmos_data_contributor" {
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.agent_cosmos.name
  role_definition_id  = "${azurerm_cosmosdb_account.agent_cosmos.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.debug_user_principal_id
  scope               = azurerm_cosmosdb_account.agent_cosmos.id
  
  depends_on = [
    azurerm_role_assignment.debug_user_cosmos_reader
  ]
}

# Private endpoints

# Storage private endpoint
resource "azurerm_private_endpoint" "agent_storage" {
  name                          = "pe-ai-agent-storage"
  location                      = var.location
  resource_group_name          = data.azurerm_resource_group.main.name
  subnet_id                    = var.private_endpoint_subnet_id
  custom_network_interface_name = "nic-ai-agent-storage"
  
  private_service_connection {
    name                           = "ai-agent-storage"
    private_connection_resource_id = azurerm_storage_account.agent_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name = "ai-agent-storage"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.blob_storage.id
    ]
  }
  
  tags = var.tags
}

# Cosmos DB private endpoint
resource "azurerm_private_endpoint" "agent_cosmos" {
  name                          = "pe-ai-agent-threads"
  location                      = var.location
  resource_group_name          = data.azurerm_resource_group.main.name
  subnet_id                    = var.private_endpoint_subnet_id
  custom_network_interface_name = "nic-ai-agent-threads"
  
  private_service_connection {
    name                           = "ai-agent-cosmosdb"
    private_connection_resource_id = azurerm_cosmosdb_account.agent_cosmos.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name = "ai-agent-cosmosdb"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.cosmos_db.id
    ]
  }
  
  tags = var.tags
}

# AI Search private endpoint
resource "azurerm_private_endpoint" "agent_search" {
  name                          = "pe-ai-agent-search"
  location                      = var.location
  resource_group_name          = data.azurerm_resource_group.main.name
  subnet_id                    = var.private_endpoint_subnet_id
  custom_network_interface_name = "nic-ai-agent-search"
  
  private_service_connection {
    name                           = "ai-agent-search"
    private_connection_resource_id = azurerm_search_service.agent_search.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }
  
  private_dns_zone_group {
    name = "ai-agent-search"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.ai_search.id
    ]
  }
  
  tags = var.tags
}

# Azure diagnostics

# Enable logging on the Storage account blob service
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "default"
  target_resource_id        = "${azurerm_storage_account.agent_storage.id}/blobServices/default"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "StorageRead"
  }
  
  enabled_log {
    category = "StorageWrite"
  }
  
  enabled_log {
    category = "StorageDelete"
  }
}

# Enable logging on the Cosmos DB account
resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name                       = "default"
  target_resource_id        = azurerm_cosmosdb_account.agent_cosmos.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "DataPlaneRequests"
  }
  
  enabled_log {
    category = "PartitionKeyRUConsumption"
  }
  
  enabled_log {
    category = "ControlPlaneRequests"
  }
}

# Enable logging on the AI Search service
resource "azurerm_monitor_diagnostic_setting" "search" {
  name                       = "default"
  target_resource_id        = azurerm_search_service.agent_search.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "OperationLogs"
  }
}