terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Backend 설정은 backend.tf 파일에서 관리합니다.
  # S3 + DynamoDB를 사용하여 state 파일 저장 및 락킹을 관리합니다.
}

provider "aws" {
  region = var.aws_region
}
