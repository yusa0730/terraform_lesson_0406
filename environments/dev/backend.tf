provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  required_version = ">= 0.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.51"
    }
  }
  backend "s3" {
    bucket = "infrastructure-lesson-bucket"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
