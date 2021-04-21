terraform {
  backend "azurerm" {
    resource_group_name  = "webapp-terraconcept-westus2"
    storage_account_name = "terrabackenddev"
    container_name       = "terrabackend"
    key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
############################
#create a new resource group
############################
resource "azurerm_resource_group" "webRG" {
  name     = var.resource_groups.webdev.name
  location = var.resource_groups.webdev.location
  tags     = var.resource_tags
}

resource "azurerm_app_service_plan" "appPlanAlpha" {
  name                = var.app_service_plan.name
  location            = var.resource_groups.webdev.location
  resource_group_name = var.resource_groups.webdev.name
  kind                = var.app_service_plan.kind
  reserved            = false

  sku {
    tier = var.app_service_plan_sku.tier
    size = var.app_service_plan_sku.size
  }

  depends_on = [
    azurerm_resource_group.webRG
  ]

}


resource "azurerm_app_service" "appServAlpha" {
  name                = var.dev_app_service.name
  location            = var.resource_groups.webdev.location
  resource_group_name = var.resource_groups.webdev.name
  app_service_plan_id = azurerm_app_service_plan.appPlanAlpha.id

  site_config {
    dotnet_framework_version = var.dev_app_service.dotnet_framework_version
  }

  depends_on = [
    azurerm_app_service_plan.appPlanAlpha
  ]
}
