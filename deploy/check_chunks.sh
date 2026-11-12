#!/bin/bash
cd /www/wwwroot/yufams/js
FAIL=0
for f in *.js; do
  if ! node --check "$f" >/dev/null 2>/tmp/ncerr; then
    echo "SYNTAX_FAIL: $f"; head -5 /tmp/ncerr; FAIL=1
  fi
done
[ $FAIL -eq 0 ] && echo "ALL_CHUNKS_OK"
echo "== inventory chunk =="
grep -l "处理差异" *.js 2>/dev/null
grep -l "assetsInventory\|盘点工作台" *.js 2>/dev/null | head
echo DONE
