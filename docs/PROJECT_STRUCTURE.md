# 프로젝트 구조 (Project Structure)

```
foodDonor-aws/                    # 루트 디렉토리
├── 📄 Core Terraform Files
│   ├── main.tf                    # 루트 모듈 (전체 리소스 조립)
│   ├── variables.tf               # 전역 변수 정의
│   ├── outputs.tf                 # 최종 출력값
│   ├── provider.tf                # AWS 프로바이더 설정
│   └── backend.tf                 # Terraform Backend 설정 (S3 + DynamoDB)
│
├── 📝 Configuration Files
│   ├── terraform.tfvars.example   # 변수 예시 파일
│   └── .gitignore                 # Git 제외 파일 목록
│
├── 📚 Examples
│   └── examples/
│       ├── backend.tf.example     # Backend 설정 예시
│       └── backend-config.hcl.example # Backend 설정 예시 (HCL)
│
├── 🔧 Scripts
│   └── scripts/
│       └── migrate-backend.sh     # Backend 마이그레이션 스크립트
│
├── 📖 Documentation
│   └── docs/
│       ├── DEPLOYMENT_GUIDE.md    # 배포 가이드
│       ├── BACKEND_SETUP.md       # Backend 설정 가이드
│       ├── BACKEND_MIGRATION.md    # Backend 마이그레이션 가이드
│       ├── GITHUB_SETUP.md        # GitHub 업로드 가이드
│       ├── CONTRIBUTING.md        # 기여 가이드
│       ├── REFACTORING_SUMMARY.md # 리팩토링 요약
│       └── TERRAFORM_INSTALL.md   # Terraform 설치 가이드
│
└── 🧩 Modules (재사용 가능한 모듈)
    ├── storage/                   # S3 Buckets (Backend 리소스 포함)
    │   ├── s3.tf
    │   ├── backend.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── database/                  # DynamoDB Tables & Glue Jobs
    │   ├── dynamodb.tf
    │   ├── glue.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── glue_outputs.tf
    │
    ├── compute/                   # Lambda Functions
    │   ├── lambda.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── integration/               # SQS & API Gateway
    │   ├── sqs.tf
    │   ├── api-gateway.tf
    │   ├── api_gateway_outputs.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── security/                  # IAM Roles & Cognito
        ├── iam.tf
        ├── cognito.tf
        ├── variables.tf
        └── outputs.tf
```

## 파일 설명

### Core Terraform Files
- **main.tf**: 모든 모듈을 조립하는 루트 모듈
- **variables.tf**: 전역 변수 정의
- **outputs.tf**: 최종 출력값 (API Gateway URL, Cognito ID 등)
- **provider.tf**: AWS 프로바이더 및 Terraform 버전 설정
- **backend.tf**: S3 + DynamoDB Backend 설정

### Modules
각 모듈은 독립적으로 관리되며, 필요한 리소스만 포함합니다.

- **storage**: S3 버킷 및 Backend 리소스
- **database**: DynamoDB 테이블 및 Glue ETL 작업
- **compute**: Lambda 함수들
- **integration**: SQS 큐 및 API Gateway
- **security**: IAM 역할/정책 및 Cognito User Pool

### Documentation
모든 상세 문서는 `docs/` 폴더에 있습니다. 각 문서는 특정 주제에 대한 상세 가이드를 제공합니다.

