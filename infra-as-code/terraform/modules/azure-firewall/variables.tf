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

variable "virtual_network_name" {
  description = "The name of the workload's virtual network in this resource group. Azure Firewall and its management NIC will be deployed into this network."
  type        = string
  
  validation {
    condition     = length(var.virtual_network_name) > 0
    error_message = "Virtual network name must be provided."
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

variable "agents_egress_subnet_name" {
  description = "The name of the subnet containing the Azure AI Foundry Agents. Must be in the same virtual network that is provided."
  type        = string
  
  validation {
    condition     = length(var.agents_egress_subnet_name) >= 8
    error_message = "Agents egress subnet name must be at least 8 characters."
  }
}

variable "jump_boxes_subnet_name" {
  description = "The name of the subnet containing your jump boxes. Must be in the same virtual network that is provided."
  type        = string
  
  validation {
    condition     = length(var.jump_boxes_subnet_name) >= 8
    error_message = "Jump boxes subnet name must be at least 8 characters."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}