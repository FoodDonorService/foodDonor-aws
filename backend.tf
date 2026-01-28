# Terraform Backend Configuration (S3 + DynamoDB)
# State 파일을 S3에 저장하고 DynamoDB로 락킹 관리

terraform {
  backend "s3" {
    bucket         = "food-donor-terraform-state-dev"
    key            = "terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "food-donor-terraform-locks-dev"
    
    # Optional: 특정 프로필 사용 시
    # profile = "your-aws-profile"
  }
}
