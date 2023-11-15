terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}