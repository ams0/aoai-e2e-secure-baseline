# Jump Box module - Deploy Azure Bastion and Windows VM for secure access

locals {
  bastion_host_name = "ab-jump-box"
  jump_box_name    = "jump-box"
  vm_name          = "vm-${local.jump_box_name}"
  nic_name         = "nic-${local.jump_box_name}"
  dcr_name         = "dcr-${local.jump_box_name}"
}

# Get current resource group data
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Existing resources

# Get existing virtual network
data "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Get existing subnets
data "azurerm_subnet" "jump_box" {
  name                 = var.jump_box_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

# Get existing Log Analytics workspace
data "azurerm_log_analytics_workspace" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  # Extract workspace name from the resource ID
  name = split("/", var.log_analytics_workspace_id)[8]
}

# New resources

# Required public IP for the Azure Bastion service
resource "azurerm_public_ip" "bastion" {
  name                = "pip-${local.bastion_host_name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  
  domain_name_label = "${local.bastion_host_name}-${var.base_name}"
  
  ddos_protection_mode    = "VirtualNetworkInherited"
  ddos_protection_plan_id = null
  
  tags = var.tags
}

# Deploy Azure Bastion for secure access to the jump box
resource "azurerm_bastion_host" "main" {
  name                = local.bastion_host_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Basic"
  scale_units         = 2
  
  copy_paste_enabled     = true
  file_copy_enabled      = false
  ip_connect_enabled     = false
  kerberos_enabled       = false
  shareable_link_enabled = false
  tunneling_enabled      = false
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = data.azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
  
  tags = var.tags
}

# Data Collection Rule for VM Insights
resource "azurerm_monitor_data_collection_rule" "vm_insights" {
  name                = local.dcr_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  kind                = "Windows"
  description         = "Standard data collection rule for VM Insights"
  
  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_workspace_id
      name                  = data.azurerm_log_analytics_workspace.main.name
    }
  }
  
  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-ServiceMap"]
    destinations = [data.azurerm_log_analytics_workspace.main.name]
  }
  
  data_sources {
    performance_counter {
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VMInsights\\DetailedMetrics"]
      name                          = "VMInsightsPerfCounters"
    }
    
    extension {
      streams            = ["Microsoft-ServiceMap"]
      extension_name     = "DependencyAgent"
      extension_json     = "{}"
      name               = "DependencyAgentDataSource"
    }
  }
  
  tags = var.tags
}

# Network interface for the jump box VM
resource "azurerm_network_interface" "jump_box" {
  name                 = local.nic_name
  location             = var.location
  resource_group_name  = data.azurerm_resource_group.main.name
  accelerated_networking_enabled = false
  ip_forwarding_enabled          = false
  
  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.jump_box.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
  
  tags = var.tags
}

# Jump box virtual machine
resource "azurerm_windows_virtual_machine" "jump_box" {
  name                = local.vm_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  size                = "Standard_D2s_v3"
  admin_username      = var.jump_box_admin_name
  admin_password      = var.jump_box_admin_password
  computer_name       = "jumpbox"
  license_type        = "Windows_Client"
  zone                = "1"
  
  
  network_interface_ids = [
    azurerm_network_interface.jump_box.id,
  ]
  
  identity {
    type = "SystemAssigned"
  }
  
  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 127
  }
  
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-pro"
    version   = "latest"
  }
  
  boot_diagnostics {
    storage_account_uri = null
  }
  
  # Additional capabilities
  additional_capabilities {
    ultra_ssd_enabled   = false
    hibernation_enabled = false
  }
  
  # Security profile
  secure_boot_enabled = true
  vtpm_enabled        = true
  
  # Enable automatic OS updates
  enable_automatic_updates = true
  patch_mode              = "AutomaticByOS"
  patch_assessment_mode   = "ImageDefault"
  
  tags = var.tags
}

# VM Access Extension
resource "azurerm_virtual_machine_extension" "vm_access" {
  name                       = "enablevmAccess"
  virtual_machine_id         = azurerm_windows_virtual_machine.jump_box.id
  publisher                  = "Microsoft.Compute"
  type                       = "VMAccessAgent"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true
  
  settings = "{}"
  
  tags = var.tags
}

# Azure CLI Installation Extension
resource "azurerm_virtual_machine_extension" "azure_cli" {
  name                       = "installAzureCLI"
  virtual_machine_id         = azurerm_windows_virtual_machine.jump_box.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  
  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\\\\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'\""
  })
  
  depends_on = [azurerm_virtual_machine_extension.vm_access]
  
  tags = var.tags
}

# Azure Monitor Agent Extension
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.jump_box.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.34"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  
  depends_on = [azurerm_virtual_machine_extension.azure_cli]
  
  tags = var.tags
}

# Dependency Agent Extension
resource "azurerm_virtual_machine_extension" "dependency_agent" {
  name                       = "DependencyAgentWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.jump_box.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.10"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  
  settings = jsonencode({
    enableAMA = "true"
  })
  
  depends_on = [azurerm_virtual_machine_extension.azure_monitor_agent]
  
  tags = var.tags
}

# Associate jump box with Azure Monitor Agent VM Insights DCR
resource "azurerm_monitor_data_collection_rule_association" "vm_insights" {
  name                    = "dcra-vminsights"
  target_resource_id      = azurerm_windows_virtual_machine.jump_box.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights.id
  description             = "VM Insights DCR association with the jump box."
  
  depends_on = [azurerm_virtual_machine_extension.dependency_agent]
}

# Azure diagnostics

# Diagnostics settings for Azure Bastion
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  name                       = "default"
  target_resource_id        = azurerm_bastion_host.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "BastionAuditLogs"
  }
}

# Diagnostics settings for the DCR
resource "azurerm_monitor_diagnostic_setting" "dcr" {
  name                       = "default"
  target_resource_id        = azurerm_monitor_data_collection_rule.vm_insights.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "LogErrors"
  }
}