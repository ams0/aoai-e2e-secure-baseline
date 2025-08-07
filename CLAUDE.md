# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Azure OpenAI end-to-end secure baseline architecture implemented with Infrastructure-as-Code. The project provides both **Terraform** (recommended) and **Bicep** (legacy) implementations for deploying a comprehensive secure AI platform with Azure AI Foundry, including agent services, web applications, and supporting infrastructure components.

### Infrastructure Options
- **Terraform**: `infra-as-code/terraform/` - Complete Terraform implementation with modular structure (recommended for new deployments)
- **Bicep**: `infra-as-code/bicep/` - Original Bicep templates (legacy, maintained for compatibility)

## Architecture Components

### Core Infrastructure Stack
- **Main Entry Point**: 
  - Terraform: `infra-as-code/terraform/main.tf` - Root module with provider configuration and module orchestration
  - Bicep: `infra-as-code/bicep/main.bicep` - Primary deployment template with modular resource orchestration
- **Network Foundation**: 
  - Terraform: `modules/network/` - Virtual network module with subnets, NSGs, and private DNS zones
  - Bicep: `network.bicep` - Private virtual network with segmented subnets (192.168.x.x addressing)
- **Security Layer**: 
  - Terraform: `modules/azure-policies/` + `modules/azure-firewall/` - Policy governance and network security controls
  - Bicep: `azure-firewall.bicep` + `azure-policies.bicep` - Network security controls and governance policies

### AI Platform Components
- **Azure AI Foundry**: `ai-foundry.bicep` - Core AI platform deployment with agent capabilities
- **AI Agent Dependencies**: `ai-agent-service-dependencies.bicep` - Storage, Cosmos DB, and AI Search services
- **AI Search**: `ai-search.bicep` - Knowledge search and retrieval service
- **Bing Integration**: `bing-grounding.bicep` - Internet grounding data for AI agents

### Application Layer
- **Web Application**: `web-app.bicep` - Frontend chat UI with managed identity and private endpoints
- **Application Gateway**: `application-gateway.bicep` - WAF-enabled ingress with custom domain/TLS
- **Storage Services**: `web-app-storage.bicep` + `ai-agent-blob-storage.bicep` - Application and agent data storage

### Security & Monitoring
- **Key Vault**: `key-vault.bicep` - Certificate and secrets management
- **Application Insights**: `application-insights.bicep` - Application performance monitoring
- **Jump Box**: `jump-box.bicep` - Secure administrative access via Bastion (currently commented out)

## Development Commands

### Terraform Deployment (Recommended)
```bash
# Navigate to Terraform directory
cd infra-as-code/terraform

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values

# Initialize Terraform
terraform init

# Plan deployment (review changes)
terraform plan

# Apply deployment (requires confirmation)
terraform apply

# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Show current state
terraform show

# Destroy infrastructure when needed
terraform destroy
```

### Bicep Deployment (Legacy)
```bash
# Deploy the main template (requires parameters)
az deployment group create \
  --resource-group <resource-group-name> \
  --template-file infra-as-code/bicep/main.bicep \
  --parameters baseName=<6-8-char-name> \
               customDomainName=<domain> \
               appGatewayListenerCertificate=<base64-cert> \
               jumpBoxAdminPassword=<password> \
               yourPrincipalId=<user-principal-id>

# Validate templates before deployment
az deployment group validate \
  --resource-group <resource-group-name> \
  --template-file infra-as-code/bicep/main.bicep \
  --parameters @parameters.json

# What-if deployment analysis
az deployment group what-if \
  --resource-group <resource-group-name> \
  --template-file infra-as-code/bicep/main.bicep \
  --parameters @parameters.json
```

### Bicep Linting and Validation
```bash
# Lint individual Bicep files
az bicep lint --file infra-as-code/bicep/main.bicep

# Build Bicep to ARM template
az bicep build --file infra-as-code/bicep/main.bicep

# Validate all Bicep files in directory
find infra-as-code/bicep -name "*.bicep" -exec az bicep lint --file {} \;
```

## Terraform Module Structure

### Available Modules
- **azure-policies**: Azure Policy assignments for governance and compliance
- **network**: Virtual network with subnets, NSGs, route tables, and private DNS zones
- **azure-firewall**: Network security and egress control (planned)
- **ai-foundry**: Azure AI Foundry deployment (planned)
- **ai-agent-service-dependencies**: Storage, Cosmos DB, AI Search (planned)
- **web-app**: Application hosting and private endpoints (planned)
- **application-gateway**: WAF and TLS termination (planned)

### Terraform Development Workflow
```bash
# Format code before committing
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan with specific variable file
terraform plan -var-file="terraform.tfvars"

# Apply with auto-approval for CI/CD
terraform apply -auto-approve -var-file="terraform.tfvars"
```

## Key Architecture Patterns

### Modular Infrastructure Structure
- **Main Template**: Orchestrates all components with dependency management
- **Module Pattern**: Each component is a separate module with clear interfaces
- **Parameter Validation**: Extensive parameter validation with min/max lengths and descriptions
- **Resource Naming**: Consistent naming convention using baseName parameter with resource-specific prefixes

### Security-First Design
- **Network Isolation**: Private endpoints for all PaaS services, no direct internet access
- **Firewall Controls**: Azure Firewall with restrictive egress rules for agent and application traffic  
- **Identity & Access**: Managed identities throughout, RBAC for service-to-service communication
- **Policy Governance**: Azure Policy assignments for AI Services, Cosmos DB, and other critical resources

### Deployment Strategy
- **Progressive Deployment**: Many components commented out in main.bicep for staged rollout
- **Dependency Management**: Explicit dependsOn declarations ensure proper resource creation order
- **Telemetry**: Optional Customer Usage Attribution for deployment tracking

### Network Architecture
- **Subnet Segmentation**: Dedicated subnets for different tiers (app gateway, app services, private endpoints, AI agents)
- **Address Planning**: 192.168.x.x private addressing (avoids 10.x limitation with AI Foundry Agent Service)
- **DDoS Protection**: Configurable DDoS protection plan (disabled by default for cost optimization)

## Important Configuration Notes

### Certificate Management
- App Gateway requires base64-encoded certificate in `appGatewayListenerCertificate` parameter
- Certificate files (appgw.crt, appgw.key, appgw.pfx) present in bicep directory for reference

### Principal ID Requirements
- **Terraform**: Automatically uses your current Azure CLI/PowerShell context via `data.azurerm_client_config.current.object_id`
- **Bicep**: `yourPrincipalId` parameter must be your Azure AD user object ID for portal access
- Used for RBAC assignments across AI Foundry, storage, and other services

### Staged Deployment Pattern
Most resources in main.bicep are commented out, suggesting a controlled rollout approach:
1. Core infrastructure (networking, firewall, policies, logging)
2. AI platform components (foundry, dependencies, search)
3. Application layer (web app, application gateway)
4. Supporting services (monitoring, key vault)

### Resource Dependencies
Key dependency chains:
- Network → Firewall → AI Services
- AI Foundry → Agent Dependencies → AI Foundry Project
- Storage → Web App → Application Gateway
- All services depend on Log Analytics workspace

## File Structure Notes

- Most resources are currently commented out in main.bicep for controlled deployment
- Each module follows consistent parameter patterns for location, baseName, and logging
- Private endpoint patterns are repeated across multiple services
- Security configurations emphasize private connectivity and managed identities