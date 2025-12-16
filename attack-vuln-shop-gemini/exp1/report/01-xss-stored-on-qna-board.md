# Vulnerability Report: Stored Cross-Site Scripting (XSS) on Q&A Board

## 1. Vulnerability Type
Stored Cross-Site Scripting (XSS)

## 2. Location
Q&A Board (`/board`)

## 3. Description
The VULN SHOP application's Q&A board is vulnerable to Stored Cross-Site Scripting (XSS). User-supplied input in the "Your Question" textarea is not properly sanitized, validated, or escaped before being persistently stored and subsequently rendered back to the `/board` page. This allows an attacker to inject arbitrary client-side scripts into the web page, which will then be executed in the browsers of other users who view the affected page.

The HTML comment `<!-- VULNERABILITY: Unescaped output allows XSS (except v3) -->` within the `/board` page explicitly hints at this vulnerability for versions other than 'v3'. The current version is 'v1'.

## 4. Proof of Concept (PoC)

### Step 1: Submit XSS Payload
An attacker can submit a question containing an XSS payload via a POST request to the `/board` endpoint.

**Request (example using curl):**
```bash
export TARGET="http://192.168.0.28:3000"
export MY_IP="10.0.0.103"
curl -X POST -H "X-Forwarded-For: $MY_IP" \
-d "content=<script>alert('XSS')</script>" \
$TARGET/board
```

### Step 2: Observe Payload Execution
Upon successful submission, the server redirects to the `/board` page. When any user, including the attacker or other legitimate users, navigates to the `/board` page, the injected script is executed by their browser.

**Observed in HTML response for `/board`:**
The payload `<script>alert('XSS')</script>` was found directly embedded and unescaped within the HTML structure, specifically within a `<div class="post-content">` block, indicating that it will be rendered and executed by the browser.

```html
                <div class="post">
                    <div class="post-content">
                        <!-- VULNERABILITY: Unescaped output allows XSS (except v3) -->
                        
                                    <script>alert('XSS')</script>
                                        
                    </div>
                    <div class="post-meta">
                        2025-12-10 03:59:50
                            
                    </div>
                </div>
```

## 5. Impact
A successful XSS attack can lead to various malicious activities, including but not limited to:
-   **Session Hijacking:** Stealing user session cookies, allowing the attacker to impersonate the victim.
-   **Defacement:** Modifying the content or appearance of the web page.
-   **Redirection:** Redirecting users to malicious websites.
-   **Phishing:** Tricking users into revealing sensitive information.
-   **Malware Distribution:** Forcing users to download malicious files.
-   **Performing actions on behalf of the user:** Executing operations as the logged-in user.

## 6. Suggested Mitigation
To prevent Stored XSS vulnerabilities, implement robust input validation and output encoding:
-   **Input Validation:** Validate all user input on the server-side to ensure it conforms to expected formats and does not contain malicious characters or scripts.
-   **Output Encoding:** Crucially, encode all user-supplied data that is rendered back to the HTML page. Use context-sensitive output encoding based on where the data is being placed (e.g., HTML entity encoding for HTML content, JavaScript escaping for JavaScript contexts). Avoid custom encoding solutions and rely on well-tested, up-to-date libraries or framework features.
-   **Content Security Policy (CSP):** Implement a strong Content Security Policy to restrict the sources from which scripts can be loaded and executed.
