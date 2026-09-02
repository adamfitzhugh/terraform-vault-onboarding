terraform {
  required_version = ">= 1.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.6"
    }
  }
}
