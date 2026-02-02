terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3バックエンドの設定（必要に応じて有効化）
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "iam-manager/terraform.tfstate"
  #   region = "ap-northeast-1"
  # }
}

provider "aws" {
  region = var.aws_region
}
