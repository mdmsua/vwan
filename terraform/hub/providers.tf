terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
    key              = "hub.tfstate"
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  use_cli         = true
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  alias           = "wan"
  tenant_id       = var.wan_tenant_id
  subscription_id = var.wan_subscription_id
  use_cli         = true
}
