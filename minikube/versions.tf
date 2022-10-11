terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.3"
    }
  }
}