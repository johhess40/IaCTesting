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
  })
  description = "Tags for ADO demo web app"
}