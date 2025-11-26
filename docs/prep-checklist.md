# GitHub 업로드 체크리스트

1. **코드/정책 검토**
   - Lambda, Glue, EventBridge 정책 파일에 실제 계정 ID나 버킷명이 맞는지 확인
   - 필요 시 placeholder 값(`YOUR_ACCOUNT_ID`) 등으로 치환
2. **시크릿 제거**
   - 자격증명, 토큰, 비밀 ARN 등은 SSM/Secrets Manager로 이동
   - 커밋 전 `git-secrets --scan` 또는 `detect-secrets scan`
3. **라이선스/문서**
   - 공개 저장소라면 LICENSE 지정
   - `README.md`와 서비스별 사용법 추가
4. **최초 커밋 후**
   - GitHub 원격 추가: `git remote add origin <url>`
   - `git push -u origin main`
