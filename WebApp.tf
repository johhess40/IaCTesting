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

resource "azurerm_resource_group" "testRG" {
  name     = "burl-rg-westus2-test"
  location = azurerm_resource_group.webRG.location
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

  tags = var.resource_tags

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
    http2_enabled             = true
    always_on                 = false
    use_32_bit_worker_process = true
  }

  tags = var.resource_tags

  depends_on = [
    azurerm_app_service_plan.appPlanAlpha
  ]
}

######################################################################
###Creating a template deployment to designate runtime as .NET CORE###
######################################################################
resource "azurerm_template_deployment" "webapp-corestack" {
  # This will make it .NET CORE for Stack property, and add the dotnet core logging extension
  name                = "AspNetCoreStack"
  resource_group_name = azurerm_resource_group.webRG.name
  template_body       = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "siteName": {
            "type": "string",
            "metadata": {
                "description": "The Azure App Service Name"
            }
        },
        "extensionName": {
            "type": "string",
            "metadata": {
                "description": "The Site Extension Name."
            }
        },
        "extensionVersion": {
            "type": "string",
            "metadata": {
                "description": "The Extension Version"
            }
        }
    },
    "resources": [
        {
            "apiVersion": "2018-02-01",
            "name": "[parameters('siteName')]",
            "type": "Microsoft.Web/sites",
            "location": "[resourceGroup().location]",
            "properties": {
                "name": "[parameters('siteName')]",
                "siteConfig": {
                    "appSettings": [],
                    "metadata": [
                        {
                            "name": "CURRENT_STACK",
                            "value": "dotnetcore"
                        }
                    ]
                }
            }
        },
        {
            "type": "Microsoft.Web/sites/siteextensions",
            "name": "[concat(parameters('siteName'), '/', parameters('extensionName'))]",
            "apiVersion": "2018-11-01",
            "location": "[resourceGroup().location]",
            "properties": {
                "version": "[parameters('extensionVersion')]"
            }
        }
    ]
}
  DEPLOY
  parameters = {
    "siteName"         = azurerm_app_service.appServAlpha.name
    "extensionName"    = "Microsoft.AspNetCore.AzureAppServices.SiteExtension"
    "extensionVersion" = "3.1.7"
  }
  deployment_mode = "Incremental"
  depends_on      = [azurerm_app_service.appServAlpha]
}