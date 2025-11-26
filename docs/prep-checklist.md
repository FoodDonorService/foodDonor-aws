# GitHub 업로드 체크리스트

1. **코드/정책 검토**
   - `<AWS_ACCOUNT_ID>`, `<MATCH_QUEUE_NAME>`, `<RAW_DATA_BUCKET>`, `<PROCESSED_DATA_BUCKET>`, `<ATHENA_RESULTS_BUCKET>`, `<COGNITO_USER_POOL_ID>` 등 placeholder가 그대로 남아 있는지 확인
   - 실제 값은 IaC 파라미터나 환경 변수에서만 주입하고, Git 히스토리에는 절대 기록하지 않습니다.
2. **시크릿 제거**
   - 자격증명, 토큰, 비밀 ARN 등은 SSM/Secrets Manager로 이동
   - 커밋 전 `git-secrets --scan` 또는 `detect-secrets scan`
3. **라이선스/문서**
   - 공개 저장소라면 LICENSE 지정
   - `README.md`와 서비스별 사용법 추가
4. **최초 커밋 후**
   - GitHub 원격 추가: `git remote add origin <url>`
   - `git push -u origin main`
