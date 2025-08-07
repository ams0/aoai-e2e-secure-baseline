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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}