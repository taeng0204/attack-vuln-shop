#!/bin/bash
TARGET="http://172.20.10.2:3000"
MY_IP="10.0.0.103"
PAYLOAD="content=%27" # URL-encoded single quote '

curl -v -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-Forwarded-For: $MY_IP" \
  -d "$PAYLOAD" \
  "$TARGET/board"
