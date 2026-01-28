# Terraform Backend 마이그레이션 가이드

이 가이드는 로컬 state 파일을 S3 + DynamoDB backend로 마이그레이션하는 방법을 설명합니다.

## 현재 상태

- ✅ Backend 리소스가 이미 생성되어 있습니다:
  - S3 Bucket: `food-donor-terraform-state-dev`
  - DynamoDB Table: `food-donor-terraform-locks-dev`
- ✅ `backend.tf` 파일이 생성되어 있습니다.

## 마이그레이션 절차

### 1. 현재 state 백업 (선택사항)

```bash
cd food-donor-infra

# 현재 state 파일 백업
cp terraform.tfstate terraform.tfstate.backup.local.$(date +%Y%m%d_%H%M%S)
cp terraform.tfstate.backup terraform.tfstate.backup.backup.local.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
```

### 2. Backend로 마이그레이션

```bash
# 방법 1: 스크립트 사용 (권장)
./scripts/migrate-backend.sh

# 방법 2: 직접 실행
terraform init -migrate-state
```

이 명령을 실행하면:
1. `backend.tf` 파일의 설정을 읽습니다
2. 기존 로컬 state 파일을 S3로 업로드합니다
3. 이후 모든 작업은 S3 backend를 사용합니다

### 3. 마이그레이션 확인

```bash
# State가 S3에 저장되었는지 확인
terraform state list

# S3 버킷에서 state 파일 확인
aws s3 ls s3://food-donor-terraform-state-dev/
```

### 4. 로컬 state 파일 정리 (선택사항)

마이그레이션이 성공적으로 완료되면 로컬 state 파일을 삭제할 수 있습니다:

```bash
# 주의: 백업이 있는지 확인 후 삭제
rm terraform.tfstate terraform.tfstate.backup
```

⚠️ **주의**: 마이그레이션이 완료되고 S3에서 state를 확인한 후에만 로컬 파일을 삭제하세요.

## 문제 해결

### 마이그레이션 실패 시

만약 마이그레이션이 실패하면:

1. **로컬 state 복원**:
   ```bash
   # backend.tf를 임시로 이름 변경
   mv backend.tf backend.tf.disabled
   terraform init
   ```

2. **문제 해결 후 재시도**:
   ```bash
   mv backend.tf.disabled backend.tf
   terraform init -migrate-state
   ```

### State 잠금 문제

만약 state가 잠겨있다면:

```bash
# DynamoDB에서 잠금 확인
aws dynamodb scan --table-name food-donor-terraform-locks-dev

# 필요시 잠금 제거 (주의: 다른 작업이 실행 중이 아닐 때만)
aws dynamodb delete-item \
  --table-name food-donor-terraform-locks-dev \
  --key '{"LockID":{"S":"<LockID>"}}'
```

## 팀 협업

Backend가 설정되면:
- ✅ 여러 개발자가 동시에 작업할 수 있습니다 (DynamoDB 락킹)
- ✅ State 파일이 중앙에서 관리됩니다 (S3)
- ✅ State 파일의 버전 관리가 자동으로 됩니다 (S3 버전 관리)
- ✅ State 파일이 암호화되어 저장됩니다 (S3 암호화)

## 참고

- Backend 설정은 `terraform init` 시에만 적용됩니다.
- Backend를 변경하려면 `terraform init -migrate-state`를 다시 실행해야 합니다.
- Backend 설정은 `backend.tf` 파일에서 관리됩니다.
