provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

terraform {
  backend "s3" {
    bucket         = "tf-state-management-824398329482348"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tfstate"
  }
}