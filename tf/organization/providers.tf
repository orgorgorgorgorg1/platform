//pass back-end config during terraform init
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "state-rg"
    storage_account_name = "state-sa-name"
    container_name       = "tfstate"
    key                  = "tfstate.tfstate"
    use_oidc = true

  }
}

provider "azurerm" {
  features {}
  use_oidc = true

}

provider "github" { 
  token = var.github_token
  //for rotterdam, probably have to set base_url to the version that supports data locality
}