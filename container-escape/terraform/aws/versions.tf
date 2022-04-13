terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.16.0"
    }
  }
}