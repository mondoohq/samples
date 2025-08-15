provider "aws" {
  region = var.region

   version = "~> 5.0"

  default_tags {
    tags = var.default_tags
  }
}