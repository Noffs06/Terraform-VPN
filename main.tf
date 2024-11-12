terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}


provider "azurerm" {
  features {}
  subscription_id = var.subId
}
variable "subId" {
  default = "8ca6be09-3c18-46f7-8e07-281d8fe0cf9d"
}



provider "aws" {
  region                   = "us-east-1"
  shared_config_files      = ["C:/Users/48558792828/.aws/config"]
  shared_credentials_files = ["C:/Users/48558792828/.aws/credentials"]

  default_tags {
    tags = {
      owner      = "Gustavo"
      managed-by = "Terraform134"
    }


  }
}