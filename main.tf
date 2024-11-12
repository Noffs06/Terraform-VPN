provider "azurerm" {
  features {}
  subscription_id = var.subId
}
variable "subId" {
  default = "8ca6be09-3c18-46f7-8e07-281d8fe0cf9d"
}