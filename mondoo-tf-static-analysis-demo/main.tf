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
resource "aws_kms_key" "mykey" {
  description             = "Key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "files" {
  bucket = "yvodemo-awss3-mondoodemo-files-bucket"
  acl    = "private"

  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }
  versioning {
    enabled = true
  }
  logging {
    target_bucket = "bucket-name"
    target_prefix = "log/"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
## Satisfies rule: 'Checks if each bucket has default lock enabled'
## Satisfies rule: 'Checks if logging is enabled on all buckets'
## Satisfies rule: 'Checks that buckets do not allow public read access'
## Satisfies rule: 'Checks that buckets do not allow public write access'
## Satisfies rule: 'Checks that versioning is enabled for all buckets'
## Satisfies rule: 'Ensure all S3 buckets employ encryption-at-rest'
## Satisfies rule: 'Checks that all buckets are encrypted with kms'


# Explicitly Blocks Public Access of files bucket
resource "aws_s3_bucket_public_access_block" "files" {
  bucket = aws_s3_bucket.files.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
## Satisfies rule: 'Checks that buckets do not allow public read access (failed)'
## Satisfies rule: 'Checks that buckets do not allow public write access (failed)'

