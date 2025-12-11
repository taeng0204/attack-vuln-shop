# VULN-SHOP Mock Penetration Test Summary Report

## 1. Introduction
This report summarizes the findings of a black-box penetration test conducted on the VULN-SHOP mock e-commerce application. The primary objective was to identify various vulnerabilities within the application to collect data for NIDS learning, adhering to the conditions outlined in the provided `GUIDE.md`.

## 2. Environment Setup & Initial Reconnaissance
The target URL was initially provided as `http://10.210.136.53:3000`. Initial attempts to connect using `curl`, `ping`, and `nmap` failed, indicating a network connectivity issue or an inaccessible host. After receiving an updated IP address `http://192.168.0.28:3000` from the user, connectivity was successfully established. All subsequent requests were made including the `X-Forwarded-For: 10.0.0.103` header as required.

## 3. Vulnerability Findings

### 3.1. Stored Cross-Site Scripting (XSS) on Q&A Board
-   **Description:** The Q&A board (`/board`) is vulnerable to stored XSS. User input in the "Your Question" textarea is not properly sanitized or escaped, allowing for the injection of arbitrary client-side scripts.
-   **Proof of Concept:** Posting `<script>alert('XSS')</script>` to the board results in the script being executed when any user views the board.
-   **Impact:** Session hijacking, defacement, redirection, malware distribution.
-   **Reference Report:** `report/01-xss-stored-on-qna-board.md`

### 3.2. SQL Injection (Authentication Bypass) on Login Form
-   **Description:** The login form (`/login`) is susceptible to SQL Injection. Input in the `username` and `password` fields is not properly handled, allowing an attacker to inject malicious SQL code to bypass authentication.
-   **Proof of Concept:** Using `username=admin' OR '1'='1&password=admin' OR '1'='1` successfully bypasses authentication, leading to a redirect to the homepage (`/`).
-   **Impact:** Unauthorized access to the application, potentially as an administrator or any other user.
-   **Reference Report:** `report/02-sql-injection-login-bypass.md`

### 3.3. Insecure Direct Object Reference (IDOR) on Order Details
-   **Description:** The order details page (`/order?id=...`) is vulnerable to IDOR. The application lacks proper authorization checks, allowing authenticated users to view any order by manipulating the `id` parameter in the URL. An explicit comment `(This is sensitive info exposed via IDOR)` in the HTML source confirms this.
-   **Proof of Concept:** After logging in, changing the `id` parameter in `/order?id=1` to `/order?id=2` reveals details of a different order belonging to another user.
-   **Impact:** Unauthorized access to sensitive order information, including product details, total costs, and User IDs of other customers.
-   **Reference Report:** `report/03-idor-on-order-details.md`

### 3.4. Stored XSS via Malicious SVG File Upload
-   **Description:** The profile image upload functionality (`/profile/upload`) allows for arbitrary file uploads, including malicious SVG files containing embedded JavaScript. When a user's profile is viewed, the uploaded SVG is rendered, and the embedded script is executed.
-   **Proof of Concept:** Uploading an `xss.svg` file containing `<script>alert('XSS from SVG');</script>` successfully updates the profile image. When the profile page is loaded, the script within the SVG executes.
-   **Impact:** Similar to other stored XSS vulnerabilities, including session hijacking, defacement, and malware distribution.
-   **Reference Report:** `report/04-stored-xss-via-svg-upload.md`

## 4. Unsuccessful Attempts & Observations

### 4.1. Admin Panel Discovery
Attempts to access common administrative paths like `/admin` and `/dashboard` (both without and with `isAdmin=true` cookie manipulation) resulted in "Cannot GET /" errors. This suggests these paths are either non-existent, protected by other mechanisms, or located elsewhere.

### 4.2. Privilege Escalation via `isAdmin` Cookie
While a cookie named `isAdmin` was observed set to `false` upon login, modifying its value to `true` did not grant access to the `/admin` or `/dashboard` paths. This implies that the application performs server-side validation for administrative privileges beyond a simple client-side cookie check, or that these specific paths are not controlled by this cookie.

### 4.3. XSS via Username Reflection (Signup)
An attempt was made to inject an XSS payload (`<script>alert('XSS_SIGNUP')</script>`) during user signup. The payload was not reflected on the homepage, profile page, order history, or order details page. It is possible the username is properly sanitized in these contexts, or reflection occurs on an undiscovered page.

### 4.4. "SEC: v1" Indicator
The "SEC: v1" indicator present in the application's header (HTML content) was noted. Inspection of HTTP headers and session cookies did not reveal a direct `SEC` header or cookie that could be easily manipulated. Its purpose is likely internal application logic or a visual indicator of the current security version.

## 5. Conclusion
The VULN-SHOP application, despite being a mock environment, demonstrates several critical web application vulnerabilities, including:
-   Multiple instances of Stored Cross-Site Scripting (XSS).
-   A severe SQL Injection flaw leading to authentication bypass.
-   An Insecure Direct Object Reference (IDOR) allowing unauthorized access to sensitive data.

These findings highlight significant security weaknesses that would need urgent attention in a production environment. The exercise successfully achieved its objective of identifying diverse vulnerabilities.
