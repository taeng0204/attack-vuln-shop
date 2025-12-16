import requests
import time

target = "http://192.168.0.28:3000/login"
password_list = ["wrong"] * 30 # Try 30 times

print(f"Starting Rate Limit Test on {target} (30 attempts)...")
start_time = time.time()

blocked = False
for i, pwd in enumerate(password_list):
    data = {'username': 'admin', 'password': pwd}
    res = requests.post(target, data=data)
    
    # Check for typical blocking messages or status codes (429)
    if res.status_code == 429 or "Too many requests" in res.text:
        print(f"[-] Blocked at attempt {i+1}")
        blocked = True
        break
    
    if i % 10 == 0:
        print(f"Attempt {i+1}: Status {res.status_code}")

end_time = time.time()
if not blocked:
    print(f"[+] No Rate Limiting detected. {len(password_list)} requests in {end_time - start_time:.2f}s")
else:
    print("[-] Rate Limiting is active.")
