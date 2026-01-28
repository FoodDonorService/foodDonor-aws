# Terraform Backend 설정 가이드 (S3 + DynamoDB)

## 개요

Terraform state 파일을 S3에 저장하고 DynamoDB로 lock 관리를 설정하는 방법입니다.

## 설정 방법

### 방법 1: 처음부터 Backend 사용 (권장)

#### Step 1: Backend 리소스 생성

먼저 backend용 S3 bucket과 DynamoDB table을 생성합니다:

```bash
# 루트 디렉토리에서 실행
# Backend 리소스만 먼저 생성
terraform init
terraform apply -target=module.storage.aws_s3_bucket.terraform_state \
                 -target=module.storage.aws_s3_bucket_versioning.terraform_state \
                 -target=module.storage.aws_s3_bucket_server_side_encryption_configuration.terraform_state \
                 -target=module.storage.aws_s3_bucket_public_access_block.terraform_state \
                 -target=module.storage.aws_dynamodb_table.terraform_locks
```

#### Step 2: Backend 설정 활성화

`backend.tf` 파일에서 backend 설정 확인 및 수정:

```hcl
backend "s3" {
  bucket         = "food-donor-terraform-state-dev"  # 실제 생성된 bucket 이름
  key            = "terraform.tfstate"
  region         = "ap-northeast-2"
  encrypt        = true
  dynamodb_table = "food-donor-terraform-locks-dev"  # 실제 생성된 table 이름
}
```

**참고**: Backend 설정은 `backend.tf` 파일에서 관리됩니다. 변수는 `terraform.tfvars`에서 설정하고, `terraform init` 시 `-backend-config` 옵션을 사용하거나 `backend-config.hcl` 파일을 사용할 수 있습니다.

#### Step 3: Backend로 마이그레이션

```bash
# Backend 설정 후 다시 초기화
terraform init -migrate-state

# 확인 메시지가 나오면 "yes" 입력
```

### 방법 2: Local State에서 Backend로 마이그레이션

이미 local state로 작업 중이라면:

#### Step 1: Backend 리소스 생성

```bash
terraform apply -target=module.storage.aws_s3_bucket.terraform_state \
                 -target=module.storage.aws_dynamodb_table.terraform_locks
```

#### Step 2: Backend 설정 추가

`backend.tf` 파일에 backend 설정이 있는지 확인 (이미 생성되어 있음)

#### Step 3: State 마이그레이션

```bash
terraform init -migrate-state
```

## Backend 설정 파일 (backend.tf) 사용 (권장)

현재 프로젝트는 `backend.tf` 파일을 사용합니다. 변수를 사용하려면 `terraform init` 시 설정을 전달합니다:

### 1. backend-config 파일 생성

`examples/backend-config.hcl.example`을 참고하여 `backend-config.hcl` 파일 생성:

```hcl
bucket         = "food-donor-terraform-state-dev"
key            = "terraform.tfstate"
region         = "ap-northeast-2"
encrypt        = true
dynamodb_table = "food-donor-terraform-locks-dev"
```

### 3. 초기화

```bash
terraform init -backend-config=backend-config.hcl
```

## 자동화된 설정 (권장)

현재 프로젝트는 `backend.tf` 파일을 사용합니다. `terraform init` 시:

```bash
terraform init \
  -backend-config="bucket=food-donor-terraform-state-dev" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=ap-northeast-2" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=food-donor-terraform-locks-dev"
```

## 확인

Backend가 제대로 설정되었는지 확인:

```bash
terraform init
# "Terraform has been successfully initialized!" 메시지 확인

# State 파일 위치 확인
terraform state list
```

## 주의사항

1. **Backend 리소스는 먼저 생성해야 합니다**
   - S3 bucket과 DynamoDB table이 존재해야 backend를 사용할 수 있습니다

2. **Backend 설정은 terraform init 시에만 적용됩니다**
   - 설정 변경 후에는 반드시 `terraform init`을 다시 실행해야 합니다

3. **State 파일은 민감한 정보를 포함할 수 있습니다**
   - S3 bucket에 적절한 접근 제어를 설정하세요
   - 버전 관리가 활성화되어 있어 실수로 삭제해도 복구 가능합니다

4. **Lock은 자동으로 관리됩니다**
   - `terraform apply` 실행 시 자동으로 lock이 생성됩니다
   - 작업 완료 후 자동으로 해제됩니다
   - 작업이 중단되면 수동으로 lock을 해제해야 할 수 있습니다

## Lock 해제 (필요한 경우)

작업이 중단되어 lock이 남아있는 경우:

```bash
# DynamoDB Console에서 직접 삭제하거나
aws dynamodb delete-item \
  --table-name food-donor-terraform-locks-dev \
  --key '{"LockID":{"S":"<lock-id>"}}'
```

## 문제 해결

### "Error: Failed to get existing workspaces"
- Backend 리소스가 생성되지 않았을 수 있습니다
- S3 bucket과 DynamoDB table이 존재하는지 확인하세요

### "Error: Error acquiring the state lock"
- 다른 프로세스가 state를 사용 중입니다
- Lock을 확인하고 필요시 해제하세요

### "Error: Backend configuration changed"
- Backend 설정을 변경한 후 `terraform init -reconfigure` 실행
