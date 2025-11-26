# Food Donor Mono Repo

이 저장소는 donation 서비스 관련 AWS 리소스를 단일(monorepo) 구조로 정리해 둔 공간입니다.

## 구조
- `services/aws-micro-service` : donor/recipient/user/volunteer 관련 Lambda, Cognito, S3 정책 등
- `services/aws-batch-process-pipeline` : Glue 처리, Athena 세팅, EventBridge 트리거 등 배치 파이프라인 자산

<img width="2048" height="2040" alt="image" src="https://github.com/user-attachments/assets/58edca05-fdde-4171-a9b8-177a0924b6cf" />

