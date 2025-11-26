# Food Donor Mono Repo

이 저장소는 donation 서비스 관련 AWS 리소스를 단일(monorepo) 구조로 정리해 둔 공간입니다.

## 구조
- `services/aws-micro-service` : donor/recipient/user/volunteer 관련 Lambda, Cognito, S3 정책 등
- `services/aws-batch-process-pipeline` : Glue 처리, Athena 세팅, EventBridge 트리거 등 배치 파이프라인 자산
- `services/aws-LLM+MCP-agent` : Bedrock/LLM 기반 MCP agent 관련 코드

필요 시 `infra/`, `docs/`, `scripts/` 폴더를 추가해 공통 IaC, 문서, 수동 배포 명령을 정리해 주세요.

## Git 준비
1. **민감정보 제외** : `.env`, `*.pem`, `terraform.tfvars` 등은 이미 `.gitignore`에 포함되어 있으며 커밋 전 `git status`로 누락 여부를 확인하세요.
2. **시크릿 저장소 사용** : 애플리케이션이 필요로 하는 키/토큰은 AWS SSM Parameter Store 혹은 Secrets Manager에 저장하고 코드/스크립트에서는 참조만 하도록 구성합니다.
3. **보안 스캔** : 첫 커밋 전에 `git-secrets` 또는 `detect-secrets` 같은 도구로 민감정보가 없는지 스캔하는 것을 권장합니다.

### Placeholder 바꾸기
- IAM 정책/코드 전반에 `<AWS_ACCOUNT_ID>`, `<MATCH_QUEUE_NAME>`, `<RAW_DATA_BUCKET>`, `<PROCESSED_DATA_BUCKET>`, `<ATHENA_RESULTS_BUCKET>`, `<GLUE_JOB_NAME>`, `<GLUE_DATABASE_NAME>`, `<FRONTEND_DOMAIN>` 등이 사용됩니다.
- GitHub에는 placeholder 그대로 두고, 배포 파이프라인/환경 변수에서 실제 값으로 주입하세요.
- `docs/prep-checklist.md`에 placeholder 교체 순서와 검증 포인트가 정리되어 있습니다.

### 환경 변수
- 루트 `.env.example`을 복사해 `.env`를 만든 뒤 `<PLACEHOLDER>` 항목을 모두 실제 값으로 채움 → 해당 `.env`는 절대 커밋하지 않습니다.
- Lambda/Glue 등 실행 환경에도 동일한 값을 환경 변수 혹은 AWS SSM/Secrets Manager로 주입해 하드코딩을 전면 차단했습니다.

## 초기화 예시
```bash
cd /Users/jodonghyeon/Documents/food-donor-dep
git init
git add .
git commit -m "chore: bootstrap mono repo"
```
그 후 GitHub에 새 repository를 만든 뒤 원격을 추가하고 push 하면 됩니다.
