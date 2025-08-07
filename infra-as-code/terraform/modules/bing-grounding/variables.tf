variable "resource_group_name" {
  description = "Name of the resource group where resources will be deployed"
  type        = string
}

variable "base_name" {
  description = "This is the base name for each Azure resource name (6-8 chars)"
  type        = string
  
  validation {
    condition     = length(var.base_name) >= 6 && length(var.base_name) <= 8
    error_message = "Base name must be between 6 and 8 characters."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}