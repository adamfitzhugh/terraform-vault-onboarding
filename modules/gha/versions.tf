terraform {
  required_version = ">= 1.14.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.6"
    }
  }
}
