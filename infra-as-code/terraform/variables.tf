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

variable "custom_domain_name" {
  description = "Domain name to use for App Gateway"
  type        = string
  default     = "contoso.com"
  
  validation {
    condition     = length(var.custom_domain_name) >= 3
    error_message = "Custom domain name must be at least 3 characters."
  }
}

# variable "app_gateway_listener_certificate" {
#   description = "The certificate data for app gateway TLS termination. The value is base64 encoded."
#   type        = string
#   sensitive   = true
  
#   validation {
#     condition     = length(var.app_gateway_listener_certificate) > 0
#     error_message = "App Gateway listener certificate must be provided."
#   }
# }

variable "publish_file_name" {
  description = "The name of the web deploy file. The file should reside in a deploy container in the Azure Storage account. Defaults to chatui.zip"
  type        = string
  default     = "chatui.zip"
  
  validation {
    condition     = length(var.publish_file_name) >= 5
    error_message = "Publish file name must be at least 5 characters."
  }
}

variable "jump_box_admin_password" {
  description = "Specifies the password of the administrator account on the Windows jump box. Complexity requirements: 3 out of 4 conditions below need to be fulfilled: Has lower characters, Has upper characters, Has a digit, Has a special character. Disallowed values: 'abc@123', 'P@$$w0rd', 'P@ssw0rd', 'P@ssword123', 'Pa$$word', 'pass@word1', 'Password!', 'Password1', 'Password22', 'iloveyou!'"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.jump_box_admin_password) >= 8 && length(var.jump_box_admin_password) <= 123
    error_message = "Jump box admin password must be between 8 and 123 characters."
  }
  
  validation {
    condition = !contains([
      "abc@123", "P@$$w0rd", "P@ssw0rd", "P@ssword123", "Pa$$word", 
      "pass@word1", "Password!", "Password1", "Password22", "iloveyou!"
    ], var.jump_box_admin_password)
    error_message = "Jump box admin password contains a disallowed value."
  }
}

# Principal ID is now automatically retrieved from the current Azure CLI/PowerShell context
# via data "azurerm_client_config" "current" {} in main.tf

variable "telemetry_opt_out" {
  description = "Set to true to opt-out of deployment telemetry."
  type        = bool
  default     = false
}

# Customer Usage Attribution Id
variable "cua_id" {
  description = "Customer Usage Attribution Id for telemetry tracking"
  type        = string
  default     = "a52aa8a8-44a8-46e9-b7a5-189ab3a64409"
}