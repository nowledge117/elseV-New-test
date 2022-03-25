terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0"
    }
  }
}


provider "aws" {
  region  = "us-west-2"
 }
######################################################################################
###ACM Provider####################
###############################################################
provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
}