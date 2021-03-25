terraform {
  backend "azurerm" {
    resource_group_name = "webapp-terraconcept-westus2"
    storage_account_name = "terrabackenddev"
    container_name       = "terrabackend"
    key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
    features{}
}
############################
#create a new resource group
############################
resource "azurerm_resource_group" "webRG" {
  name     = var.resource_groups.webdev.name
  location = var.resource_groups.webdev.location
  tags = var.resource_tags
}
