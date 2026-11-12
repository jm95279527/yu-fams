#!/bin/bash
echo "== index.html =="
curl -s http://localhost:88/ | head -c 500
echo ""
echo "== js/app bundles =="
ls -la /www/wwwroot/yufams/js/ | head -20
echo "== node syntax check all chunks =="
cd /www/wwwroot/yufams/js
for f in app.*.js chunk-vendors.*.js; do
  [ -f "$f" ] || continue
  node --check "$f" 2>&1 | head -3 && echo "OK: $f" || echo "SYNTAX_FAIL: $f"
done
echo DONE
