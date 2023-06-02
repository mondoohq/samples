terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.62.0"
    }

    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.62.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }

    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }

    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}