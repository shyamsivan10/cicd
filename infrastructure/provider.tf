#terraform {
#  required_version = ">= 0.13"
#  required_providers {
#    aws = {
#      source = "hashicorp/aws"
#      version = ">= 5.95.0"
#    }
#  }
#}
#test

provider "aws" {
    region = "ap-south-1"
}
