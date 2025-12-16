Timestamp: Fri Dec 12 05:08:48 PM KST 2025
## Vulnerability Assessment
### 1. SQL Injection
**Endpoint:** /login
**Confirmed Payloads:**
- ' OR 1=1 -- (Bypassed login)
- admin' -- (Logged in as admin?)
**Result:** Successful authentication bypass.
### 2. Stored XSS
**Endpoint:** /board
**Payload:** `<script>alert('XSS')</script>`
**Result:** Payload persisted and executed.
### 3. Cookie Manipulation (Privilege Escalation)
**Endpoint:** / (Header Check)
**Vulnerability:** Insecure Direct Object Reference / Client-side Session Data
**Method:** Modified cookie `isAdmin` from `false` to `true`.
**Result:** Gained access to Admin Menu (`/admin/products`, `/admin/users`).
### 4. File Upload (Stored XSS)
**Endpoint:** /profile/upload
**Method:** Uploaded file `xss.html` containing XSS payload.
**Result:** File accessible at `/uploads/xss.html` with `Content-Type: text/html`. Executes XSS.
### 5. CSRF (Cross-Site Request Forgery)
**Endpoint:** /board, /admin/products/*
**Vulnerability:** Lack of Anti-CSRF tokens.
**Result:** Attacker can forge requests (e.g., posting to board, updating products) on behalf of authenticated users.
