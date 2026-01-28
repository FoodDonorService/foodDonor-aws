# 기여 가이드 (Contributing Guide)

## GitHub에 올리기 전 체크리스트

### ✅ 필수 확인 사항

1. **민감한 정보 제거**
   - `terraform.tfvars` 파일이 `.gitignore`에 포함되어 있는지 확인
   - `terraform.tfstate*` 파일이 Git에 포함되지 않았는지 확인
   - AWS 자격 증명이나 시크릿 키가 코드에 하드코딩되지 않았는지 확인

2. **Backend 설정**
   - `backend.tf` 파일이 올바르게 설정되어 있는지 확인
   - Backend 리소스(S3, DynamoDB)가 생성되어 있는지 확인
   - State 파일이 S3로 마이그레이션되었는지 확인

3. **문서 업데이트**
   - README.md가 최신 상태인지 확인
   - 필요한 경우 추가 문서 작성

### 📝 커밋 전 확인

```bash
# Git 상태 확인
git status

# 변경된 파일 확인
git diff

# .gitignore 확인
cat .gitignore
```

### 🚫 Git에 포함되지 말아야 할 파일

다음 파일들은 `.gitignore`에 의해 자동으로 제외됩니다:
- `terraform.tfvars` (민감한 정보 포함)
- `terraform.tfstate*` (State 파일)
- `.terraform/` (Terraform 캐시)
- `*.log` (로그 파일)
- `.env*` (환경 변수 파일)

### 🔄 Backend 마이그레이션

처음 클론한 후:

```bash
# 1. 변수 파일 생성
cp examples/terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집

# 2. Backend 마이그레이션
./migrate-backend.sh
# 또는
terraform init -migrate-state
```

### 📦 초기 설정

새로운 환경에서:

```bash
# 1. 저장소 클론
git clone <repository-url>
cd foodDonor-aws

# 2. 변수 파일 생성
cp examples/terraform.tfvars.example terraform.tfvars
# terraform.tfvars 편집

# 3. Terraform 초기화
terraform init

# 4. 배포
terraform plan
terraform apply
```

## 팀 협업

- State 파일은 S3에 저장되므로 여러 개발자가 동시에 작업할 수 있습니다
- DynamoDB 락킹으로 동시 작업 충돌을 방지합니다
- State 파일 변경은 자동으로 버전 관리됩니다 (S3 버전 관리)
