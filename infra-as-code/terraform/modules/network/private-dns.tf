# Create and link Private DNS Zones used in this workload

# Azure AI Foundry related private DNS zone
resource "azurerm_private_dns_zone" "cognitive_services" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_services" {
  name                  = "cognitiveservices"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive_services.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

# Azure AI Foundry related private DNS zone
resource "azurerm_private_dns_zone" "ai_foundry" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai_foundry" {
  name                  = "aifoundry"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_foundry.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

# Azure OpenAI related private DNS zone
resource "azurerm_private_dns_zone" "azure_openai" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "azure_openai" {
  name                  = "azureopenai"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.azure_openai.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

# Azure AI Search private DNS zone
resource "azurerm_private_dns_zone" "ai_search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai_search" {
  name                  = "aisearch"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_search.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

# Blob Storage private DNS zone
resource "azurerm_private_dns_zone" "blob_storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_storage" {
  name                  = "blobstorage"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_storage.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

# Cosmos DB private DNS zone
resource "azurerm_private_dns_zone" "cosmos_db" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db" {
  name                  = "cosmosdb"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

# Azure Key Vault private DNS zone
resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net" # Cannot use 'privatelink.vault.azure.net' due to Terraform limitations
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "keyvault"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}

# App Service private DNS zone
resource "azurerm_private_dns_zone" "app_service" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = data.azurerm_resource_group.main.name
  
  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_service" {
  name                  = "webapp"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.app_service.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  
  tags = var.tags
}