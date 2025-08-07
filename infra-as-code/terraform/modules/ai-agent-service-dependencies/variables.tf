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

variable "base_name" {
  description = "This is the base name for each Azure resource name (6-8 chars)"
  type        = string
  
  validation {
    condition     = length(var.base_name) >= 6 && length(var.base_name) <= 8
    error_message = "Base name must be between 6 and 8 characters."
  }
}

variable "log_analytics_workspace_name" {
  description = "The name of the workload's existing Log Analytics workspace."
  type        = string
  
  validation {
    condition     = length(var.log_analytics_workspace_name) >= 4
    error_message = "Log Analytics workspace name must be at least 4 characters."
  }
}

variable "debug_user_principal_id" {
  description = "Assign your user some roles to support access to the Azure AI Foundry Agent dependencies for troubleshooting post deployment"
  type        = string
  
  validation {
    condition     = length(var.debug_user_principal_id) == 36
    error_message = "Principal ID must be exactly 36 characters (GUID format)."
  }
}

variable "private_endpoint_subnet_id" {
  description = "The resource ID for the subnet that private endpoints in the workload should surface in."
  type        = string
  
  validation {
    condition     = length(var.private_endpoint_subnet_id) > 0
    error_message = "Private endpoint subnet resource ID must be provided."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}