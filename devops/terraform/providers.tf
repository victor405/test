provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.us5.datadoghq.com"
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