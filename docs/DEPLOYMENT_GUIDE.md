# 배포 가이드 (Deployment Guide)

## 📋 사전 준비사항

### 1. AWS 자격 증명 설정
```bash
# AWS CLI 설정
aws configure

# 또는 환경 변수 설정
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=ap-northeast-2
```

### 2. Terraform 설치 확인
```bash
terraform version  # >= 1.0 필요
```

### 3. 소스 코드 파일 확인
다음 파일들이 존재하는지 확인하세요:
- `services/aws-micro-service/donor.js`
- `services/aws-micro-service/recipient.js`
- `services/aws-micro-service/user.js`
- `services/aws-micro-service/volunteer.js`
- `services/aws-micro-service/location.mjs` (ESM 모듈)
- `services/aws-batch-process-pipeline/ingest-trigger.js`
- `services/aws-batch-process-pipeline/glue-processor.py`

## 🚀 배포 단계

### Step 1: 변수 파일 생성
```bash
# 루트 디렉토리에서 실행
cp examples/terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` 파일을 편집하여 실제 값으로 수정:
```hcl
aws_region   = "ap-northeast-2"
project_name = "food-donor"
env          = "dev"
# ... 기타 변수들
```

### Step 2: Terraform 초기화
```bash
terraform init
```

### Step 3: 배포 계획 확인
```bash
terraform plan
```

생성될 리소스를 확인하고 문제가 없는지 검토하세요.

### Step 4: 배포 실행
```bash
terraform apply
```

확인 프롬프트가 나타나면 `yes`를 입력하세요.

### Step 5: 출력값 확인
배포 완료 후 출력값을 확인하세요:
```bash
terraform output
```

주요 출력값:
- `api_gateway_url`: API Gateway 엔드포인트 URL
- `cognito_user_pool_id`: Cognito User Pool ID
- `cognito_user_pool_client_id`: Cognito Client ID

## ⚠️ 중요 사항

### Lambda Handler 설정
Lambda 함수들이 단일 파일로 배포되므로, handler는 파일명에 맞게 설정되어 있습니다:
- `donor.js` → handler: `donor.handler`
- `recipient.js` → handler: `recipient.handler`
- `user.js` → handler: `user.handler`
- `volunteer.js` → handler: `volunteer.handler`
- `location.mjs` → handler: `location.handler` (ESM 모듈)
- `ingest-trigger.js` → handler: `ingest-trigger.handler`

### API Gateway 환경 변수 업데이트
Lambda 함수의 API Gateway 관련 환경 변수는 초기 배포 시 빈 값으로 설정됩니다.
API Gateway 생성 후 다음 명령으로 업데이트할 수 있습니다:

```bash
# 1. API Gateway ID와 Authorizer ID 확인
terraform output api_gateway_id
terraform output authorizer_id

# 2. terraform.tfvars에 추가하거나 직접 업데이트
# 또는 terraform apply를 다시 실행하면 자동으로 업데이트됩니다
```

### S3 Bucket 이름 충돌
S3 bucket 이름은 전역적으로 고유해야 합니다. 
기본값이 이미 사용 중일 수 있으므로 `terraform.tfvars`에서 고유한 이름으로 변경하세요.

## 🔧 문제 해결

### Lambda 함수 배포 실패
- 소스 파일이 존재하는지 확인
- 파일 경로가 올바른지 확인
- Handler 이름이 파일명과 일치하는지 확인

### S3 Bucket 생성 실패
- Bucket 이름이 전역적으로 고유한지 확인
- AWS 계정에 S3 생성 권한이 있는지 확인

### DynamoDB 테이블 생성 실패
- 테이블 이름이 고유한지 확인 (같은 리전 내)
- AWS 계정에 DynamoDB 생성 권한이 있는지 확인

## 📝 다음 단계

1. **API Gateway 테스트**
   ```bash
   # API Gateway URL 확인
   terraform output api_gateway_url
   
   # 테스트 요청
   curl https://your-api-gateway-url/v0/user/me
   ```

2. **Cognito 사용자 생성**
   - AWS Console에서 Cognito User Pool에 사용자 생성
   - 또는 AWS CLI 사용

3. **Lambda 함수 테스트**
   - AWS Console에서 Lambda 함수 직접 테스트
   - 또는 API Gateway를 통한 테스트

4. **모니터링 설정**
   - CloudWatch Logs 확인
   - X-Ray 추적 활성화 (이미 설정됨)

## 🗑️ 리소스 삭제

모든 리소스를 삭제하려면:
```bash
terraform destroy
```

⚠️ **주의**: 이 명령은 모든 리소스를 삭제합니다. 백업이 필요한 데이터는 미리 백업하세요.
