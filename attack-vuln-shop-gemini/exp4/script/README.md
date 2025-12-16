# Attack Scripts

This directory contains Python scripts used for verifying vulnerabilities in VULN-SHOP.

## Usage

### Prerequisites
- Python 3
- `requests` library (`pip install requests`)

### Scripts

1.  **`test_sqli_login.py`**
    - Tests SQL Injection on the `/login` endpoint.
    - Tries multiple payloads to bypass authentication.

2.  **`test_xss_board.py`**
    - Tests Stored XSS on the `/board` endpoint.
    - Posts a message with `<script>` tag and checks reflection.

3.  **`explore_auth.py`**
    - Logs in using SQLi and checks authenticated pages.
    - Inspects cookies.

4.  **`test_cookie_manipulation.py`**
    - Sets `isAdmin=true` cookie and checks for admin access/menus.

5.  **`test_file_upload.py`**
    - Uploads a malicious HTML file to `/profile/upload`.
    - Verification: Access the uploaded file URL (e.g., `/uploads/filename`).
