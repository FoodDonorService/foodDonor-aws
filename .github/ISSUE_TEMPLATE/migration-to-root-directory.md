# 🚀 Infrastructure Migration: food-donor-infra → Root Directory

## 📋 개요

Terraform 인프라 코드를 `food-donor-infra/` 폴더에서 루트 디렉토리로 마이그레이션하여 프로젝트 구조를 단순화하고 관리성을 향상시킵니다.

## 🎯 목표

- [x] `food-donor-infra/` 폴더의 모든 파일을 루트로 이동
- [x] 경로 참조 수정 (`../services` → `services`)
- [x] 문서 업데이트 (README, 가이드 문서)
- [x] Backend 설정 (S3 + DynamoDB) 완료
- [x] `.gitignore`, `.gitattributes`, `.editorconfig` 설정
- [x] 문서 정리 (`docs/` 폴더로 이동)

## ✅ 완료된 작업

### 1. 파일 구조 변경
- ✅ Terraform 파일들을 루트 디렉토리로 이동
- ✅ `modules/`, `docs/`, `examples/`, `scripts/` 폴더 정리
- ✅ `food-donor-infra/` 폴더 제거

### 2. 경로 참조 수정
- ✅ `modules/compute/lambda.tf`: `../services` → `services`
- ✅ `modules/database/glue.tf`: `../services` → `services`
- ✅ 주석 업데이트 (`path.root` 설명)

### 3. 문서 업데이트
- ✅ `README.md`: 프로젝트 구조 설명 업데이트
- ✅ 모든 문서 링크 경로 수정
- ✅ 문서를 `docs/` 폴더로 정리

### 4. Backend 설정
- ✅ S3 Backend 설정 (`backend.tf`)
- ✅ DynamoDB 락킹 설정
- ✅ 마이그레이션 스크립트 생성 (`scripts/migrate-backend.sh`)

### 5. 프로젝트 정리
- ✅ `.gitignore` 업데이트
- ✅ `.gitattributes` 생성
- ✅ `.editorconfig` 생성
- ✅ 예시 파일들을 `examples/` 폴더로 이동

## 🔄 변경사항

### Before
```
foodDonor-aws/
├── food-donor-infra/
│   ├── main.tf
│   ├── modules/
│   └── ...
└── services/
```

### After
```
foodDonor-aws/
├── main.tf
├── modules/
├── docs/
├── examples/
├── scripts/
└── services/
```

## 📝 영향받는 파일

- `modules/compute/lambda.tf` - 경로 참조 수정
- `modules/database/glue.tf` - 경로 참조 수정
- `README.md` - 프로젝트 구조 설명 업데이트
- 모든 문서 파일 - 경로 링크 수정

## 🧪 테스트

- [x] `terraform init` 성공
- [x] `terraform validate` 성공
- [x] `terraform plan` 성공 (8개 리소스 업데이트 예정)
- [x] 모든 Lambda 소스 파일 경로 확인

## 📚 관련 문서

- [Backend 마이그레이션 가이드](docs/BACKEND_MIGRATION.md)
- [프로젝트 구조](docs/PROJECT_STRUCTURE.md)
- [배포 가이드](docs/DEPLOYMENT_GUIDE.md)

## 🔮 향후 계획

### Phase 1: 현재 (완료)
- ✅ 인프라 코드 루트로 마이그레이션
- ✅ Backend 설정 완료
- ✅ 문서 정리

### Phase 2: CI/CD 구축 (예정)
- [ ] `services/` 폴더를 별도 레포지토리로 분리
- [ ] GitHub Actions를 통한 자동 배포 파이프라인 구축
- [ ] Lambda 함수 자동 배포 (코드 변경 시)
- [ ] Terraform 자동 배포 (인프라 변경 시)
- [ ] 테스트 자동화

자세한 내용은 [CI/CD 구축 이슈](#) 참고

## ✅ 체크리스트

- [x] 파일 이동 완료
- [x] 경로 참조 수정 완료
- [x] 문서 업데이트 완료
- [x] Backend 설정 완료
- [x] 테스트 완료
- [ ] `terraform apply` 실행 (사용자 확인 필요)

## 📌 참고사항

- 모든 변경사항은 `terraform plan`에서 확인 가능
- Lambda 함수들은 소스 코드 변경으로 인해 재배포됩니다 (무중단)
- Backend 마이그레이션은 `scripts/migrate-backend.sh` 사용

---

**작성일**: 2025-01-28  
**상태**: ✅ 완료  
**관련 PR**: #1
