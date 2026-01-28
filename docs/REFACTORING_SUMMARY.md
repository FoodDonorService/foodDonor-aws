# Terraform 리팩토링 완료 요약

## 작업 완료 내역

### ✅ 완료된 작업

1. **Provider 통합**
   - 모든 파일의 `provider "aws"` 블록 제거
   - 루트 `provider.tf`로 통합
   - `terraform` 블록 추가 (버전 및 required_providers)

2. **변수화 (Variables)**
   - `variables.tf` 생성 및 모든 하드코딩 값 변수화
   - AWS Account ID → `data.aws_caller_identity.current.account_id` 사용
   - Bucket 이름 → `var.project_name + var.env` 접두사 사용

3. **Lambda 소스 코드 연결**
   - S3 zip 파일 참조 → 로컬 소스 코드 `archive_file` 사용
   - 소스 코드 매핑:
     - `donor-service` → `services/aws-micro-service/donor.js`
     - `recipient-service` → `services/aws-micro-service/recipient.js`
     - `user-service` → `services/aws-micro-service/user.js`
     - `volunteer-service` → `services/aws-micro-service/volunteer.js`
     - `location-service` → `services/aws-micro-service/location.mjs`
     - `ingest-trigger` → `services/aws-batch-process-pipeline/ingest-trigger.js`
   - `source_code_hash` 사용으로 코드 변경 시에만 배포

4. **Glue Job 스크립트 연결**
   - S3 하드코딩 제거
   - `aws_s3_object`로 로컬 `glue-processor.py` 업로드
   - Glue Job이 업로드된 스크립트 참조

5. **의존성 및 참조 수정**
   - SQS URL 하드코딩 → `aws_sqs_queue` 리소스 참조
   - API Gateway integration_uri → `aws_lambda_function.invoke_arn` 참조
   - IAM Policies ARN 하드코딩 → Terraform interpolation 사용

6. **권한 (Permissions)**
   - API Gateway Lambda 권한 추가 (`aws_lambda_permission`)
   - 각 Lambda 함수에 대한 `AllowExecutionFromAPIGateway` 리소스 생성

7. **모듈화 구조**
   - `modules/storage` - S3 Buckets
   - `modules/database` - DynamoDB Tables & Glue Jobs
   - `modules/compute` - Lambda Functions
   - `modules/integration` - SQS & API Gateway
   - `modules/security` - IAM Roles & Cognito

## 📁 생성된 파일 구조

```
food-donor-infra/
├── main.tf              # 루트 모듈 (모든 모듈 조립)
├── variables.tf          # 전역 변수
├── outputs.tf            # 최종 출력값
├── provider.tf          # AWS 프로바이더 설정
├── terraform.tfvars     # 실제 변수 값 (gitignore 필요)
└── modules/
    ├── storage/
    │   ├── s3.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── database/
    │   ├── dynamodb.tf
    │   ├── glue.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── glue_variables.tf
    ├── compute/
    │   ├── lambda.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── integration/
    │   ├── sqs.tf
    │   ├── api-gateway.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── api_gateway_variables.tf
    └── security/
        ├── iam.tf
        ├── cognito.tf
        ├── variables.tf
        ├── cognito_variables.tf
        └── outputs.tf
```

## ⚠️ 주의사항

1. **Lambda 소스 코드 파일 필요**
   - 다음 파일들이 존재해야 합니다:
     - `services/aws-micro-service/donor.js`
     - `services/aws-micro-service/recipient.js`
     - `services/aws-micro-service/user.js`
     - `services/aws-micro-service/volunteer.js`
     - `services/aws-micro-service/location.mjs`
     - `services/aws-batch-process-pipeline/ingest-trigger.js`

2. **Glue 스크립트 파일 필요**
   - `services/aws-batch-process-pipeline/glue-processor.py` 파일 필요

3. **API Gateway 환경 변수**
   - Lambda 함수의 API Gateway 관련 환경 변수는 초기 배포 시 빈 값으로 설정됩니다
   - API Gateway 생성 후 별도로 업데이트하거나, 두 단계로 배포 필요:
     1. 첫 번째: Lambda, DynamoDB, S3 등 기본 리소스 배포
     2. 두 번째: API Gateway 생성 후 Lambda 환경 변수 업데이트

4. **terraform.tfvars**
   - 실제 변수 값은 `terraform.tfvars`에 설정
   - `.gitignore`에 추가하여 Git에 커밋하지 않도록 주의

## 🚀 배포 방법

1. **변수 설정**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # terraform.tfvars 파일 편집
   ```

2. **초기화**
   ```bash
   terraform init
   ```

3. **검증**
   ```bash
   terraform validate
   terraform plan
   ```

4. **배포**
   ```bash
   terraform apply
   ```

## 📝 다음 단계

1. Lambda 소스 코드 파일들을 `services/` 폴더에 추가
2. `terraform.tfvars` 파일 생성 및 변수 값 설정
3. `terraform init` 및 `terraform plan` 실행하여 검증
4. 필요시 API Gateway 생성 후 Lambda 환경 변수 업데이트
