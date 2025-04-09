//pass back-end config during terraform init
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "state-rg"
    storage_account_name = "state-sa-name"
    container_name       = "tfstate"
    key                  = "tfstate.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "github" { 
  token = var.github_token
  //for rotterdam, probably have to set base_url to the version that supports data locality
}