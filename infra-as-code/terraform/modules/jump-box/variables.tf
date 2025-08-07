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

variable "virtual_network_name" {
  description = "The name of the virtual network in this resource group."
  type        = string
  
  validation {
    condition     = length(var.virtual_network_name) > 0
    error_message = "Virtual network name must be provided."
  }
}

variable "jump_box_subnet_name" {
  description = "The name of the subnet for the jump box. Must be in the same virtual network that is provided."
  type        = string
  
  validation {
    condition     = length(var.jump_box_subnet_name) > 0
    error_message = "Jump box subnet name must be provided."
  }
}

variable "log_analytics_workspace_id" {
  description = "The resource ID of the workload's existing Log Analytics workspace."
  type        = string
  
  validation {
    condition     = length(var.log_analytics_workspace_id) > 0
    error_message = "Log Analytics workspace ID must be provided."
  }
}

variable "jump_box_admin_name" {
  description = "Specifies the name of the administrator account on the Windows jump box. Cannot end in \".\""
  type        = string
  default     = "vmadmin"
  
  validation {
    condition     = length(var.jump_box_admin_name) >= 4 && length(var.jump_box_admin_name) <= 20
    error_message = "Admin name must be between 4 and 20 characters."
  }
  
  validation {
    condition = !contains([
      "administrator", "admin", "user", "user1", "test", "user2", "test1", 
      "user3", "admin1", "1", "123", "a", "actuser", "adm", "admin2", 
      "aspnet", "backup", "console", "david", "guest", "john", "owner", 
      "root", "server", "sql", "support", "support_388945a0", "sys", 
      "test2", "test3", "user4", "user5"
    ], var.jump_box_admin_name)
    error_message = "Admin name contains disallowed values."
  }
}

variable "jump_box_admin_password" {
  description = "Specifies the password of the administrator account on the Windows jump box."
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.jump_box_admin_password) >= 8 && length(var.jump_box_admin_password) <= 123
    error_message = "Password must be between 8 and 123 characters."
  }
  
  validation {
    condition = !contains([
      "abc@123", "P@$$w0rd", "P@ssw0rd", "P@ssword123", "Pa$$word", 
      "pass@word1", "Password!", "Password1", "Password22", "iloveyou!"
    ], var.jump_box_admin_password)
    error_message = "Password contains disallowed values."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}