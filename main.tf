# Kubernetes provider and backend configuration for state files

terraform {
  backend "s3" {
    bucket         = "<bucket_name>"
    key            = "<key>"
    region         = "<region>"
    dynamodb_table = "<table_name>"
  }
}

locals {
  cluster_name = "a10-cloud-demo-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}
