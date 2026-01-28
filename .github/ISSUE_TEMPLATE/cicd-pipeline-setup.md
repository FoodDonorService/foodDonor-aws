# 🚀 CI/CD 파이프라인 구축

## 📋 개요

`services/` 폴더의 Lambda 함수 소스 코드를 별도 레포지토리로 분리하고, GitHub Actions를 통해 자동 배포 파이프라인을 구축합니다.

## 🎯 목표

- [ ] `services/` 폴더를 별도 레포지토리로 분리
- [ ] GitHub Actions 워크플로우 구축
- [ ] Lambda 함수 자동 배포 파이프라인
- [ ] Terraform 인프라 자동 배포 파이프라인
- [ ] 테스트 자동화
- [ ] 환경별 배포 전략 (dev, staging, prod)

## 🏗️ 아키텍처

### 현재 구조
```
foodDonor-aws/
├── modules/
├── services/          # Lambda 소스 코드
│   ├── aws-micro-service/
│   └── aws-batch-process-pipeline/
└── ...
```

### 목표 구조
```
foodDonor-aws/          # 인프라 레포지토리
├── modules/
└── .github/workflows/
    └── terraform-deploy.yml

food-donor-services/     # 서비스 레포지토리 (신규)
├── aws-micro-service/
├── aws-batch-process-pipeline/
└── .github/workflows/
    └── lambda-deploy.yml
```

## 📝 작업 계획

### Phase 1: 레포지토리 분리

#### 1.1 서비스 레포지토리 생성
- [ ] `food-donor-services` 레포지토리 생성
- [ ] `services/` 폴더 내용 이동
- [ ] 각 서비스별 README 작성
- [ ] `.gitignore` 설정

#### 1.2 인프라 레포지토리 업데이트
- [ ] Terraform 코드에서 외부 레포지토리 참조로 변경
- [ ] Git submodule 또는 외부 소스 참조 설정
- [ ] 문서 업데이트

### Phase 2: GitHub Actions 워크플로우 구축

#### 2.1 Lambda 함수 배포 파이프라인
- [ ] `.github/workflows/lambda-deploy.yml` 생성
- [ ] 코드 변경 감지 및 자동 배포
- [ ] 환경별 배포 (dev, staging, prod)
- [ ] 배포 전 테스트 실행
- [ ] 배포 알림 (Slack, Email 등)

**워크플로우 예시**:
```yaml
name: Deploy Lambda Functions

on:
  push:
    branches: [main, develop]
    paths:
      - 'services/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
      - name: Deploy to AWS Lambda
        # Lambda 배포 스크립트
```

#### 2.2 Terraform 인프라 배포 파이프라인
- [ ] `.github/workflows/terraform-deploy.yml` 생성
- [ ] `terraform plan` 자동 실행 (PR 시)
- [ ] `terraform apply` 자동 실행 (main 브랜치 머지 시)
- [ ] State 파일 관리 (S3 Backend)
- [ ] 리뷰 승인 프로세스

**워크플로우 예시**:
```yaml
name: Terraform Deploy

on:
  pull_request:
    paths:
      - '**/*.tf'
  push:
    branches: [main]
    paths:
      - '**/*.tf'

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      - name: Terraform Init
        run: terraform init
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      - name: Comment PR
        # PR에 plan 결과 코멘트
```

### Phase 3: 테스트 자동화

- [ ] Unit 테스트 설정
- [ ] Integration 테스트 설정
- [ ] Terraform 코드 검증 (`terraform validate`, `tflint`)
- [ ] 보안 스캔 (Checkov, tfsec)

### Phase 4: 모니터링 및 알림

- [ ] 배포 성공/실패 알림
- [ ] CloudWatch 알람 연동
- [ ] 배포 히스토리 추적

## 🔧 기술 스택

### CI/CD 도구
- **GitHub Actions**: 워크플로우 실행
- **Terraform**: 인프라 배포
- **AWS CLI**: Lambda 배포

### 테스트 도구
- **Jest** (Node.js): Lambda 함수 테스트
- **tflint**: Terraform 코드 린팅
- **Checkov**: Terraform 보안 스캔

### 배포 전략
- **Blue/Green 배포**: Lambda 함수 무중단 배포
- **Canary 배포**: 점진적 배포 (선택사항)
- **환경 분리**: dev → staging → prod

## 📊 배포 프로세스

### Lambda 함수 배포
1. 코드 변경 → PR 생성
2. 자동 테스트 실행
3. 리뷰 및 승인
4. main 브랜치 머지
5. 자동 배포 트리거
6. Lambda 함수 업데이트
7. 배포 알림

### 인프라 배포
1. Terraform 코드 변경 → PR 생성
2. 자동 `terraform plan` 실행
3. Plan 결과 PR 코멘트
4. 리뷰 및 승인
5. main 브랜치 머지
6. 자동 `terraform apply` 실행
7. 배포 알림

## 🔐 보안 고려사항

- [ ] AWS 자격 증명을 GitHub Secrets로 관리
- [ ] Terraform State 파일 암호화 (이미 설정됨)
- [ ] 민감한 정보는 AWS Secrets Manager 사용
- [ ] 배포 권한 최소화 (최소 권한 원칙)
- [ ] 코드 스캔 자동화

## 📚 참고 자료

- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Terraform Cloud](https://www.terraform.io/cloud)
- [AWS Lambda 배포 가이드](https://docs.aws.amazon.com/lambda/latest/dg/deploying-lambda-apps.html)

## ✅ 체크리스트

### Phase 1: 레포지토리 분리
- [ ] 서비스 레포지토리 생성
- [ ] 코드 이동 및 정리
- [ ] Terraform 코드 업데이트

### Phase 2: CI/CD 구축
- [ ] Lambda 배포 워크플로우
- [ ] Terraform 배포 워크플로우
- [ ] 환경별 배포 설정

### Phase 3: 테스트 자동화
- [ ] Unit 테스트 설정
- [ ] Integration 테스트 설정
- [ ] 보안 스캔 설정

### Phase 4: 모니터링
- [ ] 알림 설정
- [ ] 배포 히스토리 추적

## 🎯 우선순위

1. **High**: 레포지토리 분리 및 기본 CI/CD 파이프라인
2. **Medium**: 테스트 자동화 및 환경별 배포
3. **Low**: 고급 배포 전략 (Blue/Green, Canary)

## 📅 예상 일정

- **Phase 1**: 1-2주
- **Phase 2**: 2-3주
- **Phase 3**: 1-2주
- **Phase 4**: 1주

**총 예상 기간**: 5-8주

---

**작성일**: 2025-01-28  
**상태**: 📋 계획 중  
**우선순위**: High  
**관련 이슈**: #1 (Infrastructure Migration)
