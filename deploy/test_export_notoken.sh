#!/bin/bash
B=http://127.0.0.1:89
echo "=== no-token /assets/export (window.open 方式) ==="
curl -s -o /tmp/a.out -w 'HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}\n' "$B/assets/export"
head -c 200 /tmp/a.out; echo
echo "=== no-token /staff/export ==="
curl -s -o /tmp/b.out -w 'HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}\n' "$B/staff/export"
head -c 200 /tmp/b.out; echo
echo "=== no-token /assetsScrap/export ==="
curl -s -o /tmp/c.out -w 'HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}\n' "$B/assetsScrap/export"
head -c 200 /tmp/c.out; echo
echo "=== token as query param ==="
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
curl -s -o /tmp/d.out -w 'HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}\n' "$B/assets/export?token=$TOK"
head -c 20 /tmp/d.out | cat -v; echo
