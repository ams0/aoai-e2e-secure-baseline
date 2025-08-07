# Bing Grounding module - Deploy Bing Search service for AI grounding

locals {
  bing_account_name = "bing-ai-agent-${var.base_name}"
}

# Get current resource group data
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Deploy Bing Search account for grounding AI responses using ARM template
# Note: Bing Grounding accounts are not directly supported in the AzureRM provider
# Using ARM template deployment as a workaround
resource "azurerm_resource_group_template_deployment" "bing_grounding" {
  name                = "bing-grounding-deployment"
  resource_group_name = data.azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  
  template_content = jsonencode({
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "accountName": {
        "type": "string",
        "value": local.bing_account_name
      },
      "tags": {
        "type": "object",
        "value": var.tags
      }
    },
    "resources": [
      {
        "type": "Microsoft.Bing/accounts",
        "apiVersion": "2020-06-10",
        "name": "[parameters('accountName')]",
        "location": "global",
        "kind": "Bing.Search.v7",
        "sku": {
          "name": "S1"
        },
        "tags": "[parameters('tags')]"
      }
    ],
    "outputs": {
      "accountName": {
        "type": "string",
        "value": "[parameters('accountName')]"
      },
      "accountId": {
        "type": "string", 
        "value": "[resourceId('Microsoft.Bing/accounts', parameters('accountName'))]"
      }
    }
  })
}