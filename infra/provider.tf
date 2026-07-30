// Lays the foundation for Terraform, which is cloud agnostic.
// AzureRM: Azure Resource Manager.

/**
  COMMANDS:
  1. terraform init: First command to run. Prepares directory to do three things
    1. Download providers:
        Reads config and installs providers such as azure, aws, etc. Providers
        are the code that actually talks to the cloud's API. Plugins download to
        hidden .terraform/ directory.

    2. Download modules:
        If your configuration references reusable modules (local/registry), it fetches them.

    3. Set up the backend:
        Configures where state files live (locally by default, or in a remote backend
        such as Azure Storage for team use).

  2. az group create --name serverless-rg --location eastus
 */
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

// The provider name must match the source; azurerm maps to hashicorp/azurerm.
provider "azurerm" {
  features {}
}
