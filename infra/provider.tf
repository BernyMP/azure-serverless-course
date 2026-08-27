// Run `terraform init` first: it downloads providers/modules and sets up the backend.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

// Authenticates via the Azure CLI (`az login`).
provider "azurerm" {
  features {}
}
