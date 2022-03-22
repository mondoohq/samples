terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.74.3"
    }
  }

  required_version = ">= 0.14.9"
}

# Default set to AWS eu-central-1
provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

# KMS key to be used to encrypt data on buckets

resource "aws_s3_bucket" "files" {
  bucket = "yvodemo-awss3-mondoodemo-files-bucket"
  acl    = "private"
}
