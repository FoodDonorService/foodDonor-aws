# GitHub 업로드 가이드

## ✅ 업로드 전 체크리스트

### 1. 민감한 정보 확인
```bash
# terraform.tfvars가 .gitignore에 포함되어 있는지 확인
grep terraform.tfvars .gitignore

# state 파일이 제외되는지 확인
grep terraform.tfstate .gitignore
```

### 2. Backend 마이그레이션
```bash
# Backend로 state 마이그레이션
./scripts/migrate-backend.sh
# 또는
terraform init -migrate-state
```

### 3. Git 상태 확인
```bash
# 변경된 파일 확인
git status

# 커밋할 파일만 확인 (민감한 파일 제외)
git status --short | grep -v terraform.tfvars | grep -v terraform.tfstate
```

### 4. 초기 커밋 (처음 업로드하는 경우)
```bash
# Git 초기화 (이미 되어있다면 스킵)
git init

# 모든 파일 추가 (민감한 파일은 자동 제외)
git add .

# 커밋
git commit -m "Initial commit: Terraform infrastructure for Food Donor Platform"

# 원격 저장소 추가
git remote add origin <your-repository-url>

# 푸시
git push -u origin main
```

## 📝 권장 커밋 메시지

```
feat: Add Terraform infrastructure for Food Donor Platform

- Modular structure with storage, database, compute, integration, security modules
- S3 + DynamoDB backend for state management
- Lambda functions with local source code
- API Gateway with Cognito authentication
- Complete IAM roles and policies
```

## 🔒 보안 주의사항

- ✅ `terraform.tfvars`는 절대 커밋하지 마세요
- ✅ `terraform.tfstate*` 파일도 커밋하지 마세요 (S3에 저장됨)
- ✅ AWS 자격 증명을 코드에 하드코딩하지 마세요
- ✅ `.gitignore` 파일을 확인하세요

