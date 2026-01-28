# Pull Request

## 📋 변경사항 요약

<!-- 이 PR에서 변경된 주요 내용을 간단히 설명해주세요 -->

## 🎯 목적

<!-- 이 PR의 목적과 해결하려는 문제를 설명해주세요 -->

## 🔄 변경사항 상세

### 변경된 파일
- 
- 

### 주요 변경 내용
- 
- 

## 🧪 테스트

- [ ] `terraform init` 성공
- [ ] `terraform validate` 성공
- [ ] `terraform plan` 실행 및 검토 완료
- [ ] 로컬에서 테스트 완료

## 📸 스크린샷 (선택사항)

<!-- UI 변경사항이 있는 경우 스크린샷을 첨부해주세요 -->

## ✅ 체크리스트

- [ ] 코드가 프로젝트 스타일 가이드를 따릅니다
- [ ] 필요한 문서가 업데이트되었습니다
- [ ] 테스트가 추가/수정되었습니다 (해당되는 경우)
- [ ] `terraform plan` 결과를 검토했습니다
- [ ] Breaking changes가 있다면 문서화했습니다

## 🔗 관련 이슈

<!-- 관련된 이슈 번호를 입력해주세요 -->
Closes #
Related to #

## 📝 추가 정보

<!-- 리뷰어가 알아야 할 추가 정보가 있다면 작성해주세요 -->

## 🔮 향후 계획

### Phase 1: 현재 (완료)
- ✅ 인프라 코드 루트로 마이그레이션 완료
- ✅ Backend 설정 완료
- ✅ 문서 정리 완료

### Phase 2: CI/CD 구축 (예정)
- [ ] `services/` 폴더를 별도 레포지토리로 분리
- [ ] GitHub Actions를 통한 자동 배포 파이프라인 구축
- [ ] Lambda 함수 자동 배포 (코드 변경 시)
- [ ] Terraform 자동 배포 (인프라 변경 시)
- [ ] 테스트 자동화
- [ ] 환경별 배포 전략 (dev → staging → prod)

자세한 내용은 [CI/CD 구축 이슈](.github/ISSUE_TEMPLATE/cicd-pipeline-setup.md) 참고

---

**리뷰어**: @  
**라벨**: `infrastructure`, `migration`
