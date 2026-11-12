#!/bin/bash
echo "=== admin login ==="
RESP=$(curl -s http://127.0.0.1:89/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}')
echo "$RESP" | head -c 400
echo
TOK=$(echo "$RESP" | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])" 2>/dev/null)
echo "TOKEN=${TOK:0:30}..."
[ -n "$TOK" ] && echo "LOGIN OK" || echo "LOGIN FAIL"
