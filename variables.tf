variable "resource_groups" {
  description = "This is a variable for defining web app resource group"
  type = map(object({
    name     = string
    location = string
  }))
}

variable "resource_tags" {
  type = object({
    Environment = string
    Location    = string
    Owner       = string
    Tool        = string
  })
  description = "Tags for ADO demo web app"
}

variable "app_service_plan" {
  type = object({
    name = string
    kind = string
  })
}

variable "app_service_plan_sku" {
  type = object({
    tier = string
    size = string
  })
}

variable "dev_app_service" {
  type = object({
    name             = string
    linux_fx_version = string
  })
}