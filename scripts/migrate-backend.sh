#!/bin/bash
# Terraform Backend 마이그레이션 스크립트
# 로컬 state를 S3 + DynamoDB backend로 마이그레이션합니다

set -e

echo "🚀 Terraform Backend 마이그레이션 시작..."
echo ""

# 현재 디렉토리 확인
if [ ! -f "backend.tf" ]; then
    echo "❌ 오류: backend.tf 파일을 찾을 수 없습니다."
    echo "현재 디렉토리에서 실행해주세요: cd food-donor-infra"
    exit 1
fi

# State 파일 백업
if [ -f "terraform.tfstate" ]; then
    echo "📦 로컬 state 파일 백업 중..."
    cp terraform.tfstate terraform.tfstate.backup.local.$(date +%Y%m%d_%H%M%S)
    echo "✅ 백업 완료"
    echo ""
fi

# Backend로 마이그레이션
echo "🔄 Backend로 마이그레이션 중..."
terraform init -migrate-state

echo ""
echo "✅ 마이그레이션 완료!"
echo ""
echo "다음 단계:"
echo "1. terraform state list 로 state 확인"
echo "2. aws s3 ls s3://food-donor-terraform-state-dev/ 로 S3 확인"
echo "3. 마이그레이션이 성공하면 로컬 state 파일 삭제 가능 (선택사항)"
echo ""
