variable "resource_group_name" {
  description = "Name of the resource group where resources will be deployed"
  type        = string
}

variable "location" {
  description = "The region in which this architecture is deployed. Should match the region of the resource group."
  type        = string
  
  validation {
    condition     = length(var.location) > 0
    error_message = "Location must be provided."
  }
}

variable "existing_ai_foundry_name" {
  description = "The existing Azure AI Foundry account. This project will become a child resource of this account."
  type        = string
  
  validation {
    condition     = length(var.existing_ai_foundry_name) >= 2
    error_message = "AI Foundry name must be at least 2 characters."
  }
}

variable "existing_cosmos_db_account_name" {
  description = "The existing Azure Cosmos DB account that is going to be used as the Azure AI Foundry Agent thread storage database (dependency)."
  type        = string
  
  validation {
    condition     = length(var.existing_cosmos_db_account_name) >= 3
    error_message = "Cosmos DB account name must be at least 3 characters."
  }
}

variable "existing_storage_account_name" {
  description = "The existing Azure Storage account that is going to be used as the Azure AI Foundry Agent blob store (dependency)."
  type        = string
  
  validation {
    condition     = length(var.existing_storage_account_name) >= 3
    error_message = "Storage account name must be at least 3 characters."
  }
}

variable "existing_ai_search_account_name" {
  description = "The existing Azure AI Search account that is going to be used as the Azure AI Foundry Agent vector store (dependency)."
  type        = string
  
  validation {
    condition     = length(var.existing_ai_search_account_name) > 0
    error_message = "AI Search account name must be provided."
  }
}

variable "existing_bing_account_name" {
  description = "The existing Bing grounding data account that is available to Azure AI Foundry Agent agents in this project."
  type        = string
  
  validation {
    condition     = length(var.existing_bing_account_name) > 0
    error_message = "Bing account name must be provided."
  }
}

variable "existing_web_application_insights_resource_name" {
  description = "The existing Application Insights instance to log token usage in this project."
  type        = string
  
  validation {
    condition     = length(var.existing_web_application_insights_resource_name) > 0
    error_message = "Application Insights resource name must be provided."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}