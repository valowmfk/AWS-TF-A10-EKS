terraform {
  backend "s3" {
    bucket         = "<bucket_name>"
    key            = "<key>"
    region         = "<region>"
    dynamodb_table = "<table_name>"
  }
}