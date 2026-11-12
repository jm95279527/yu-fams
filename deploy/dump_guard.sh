#!/bin/bash
APP=/www/wwwroot/yufams/js/app.bf41bc40.js
python3 - "$APP" <<'PY'
import sys, re
js = open(sys.argv[1], encoding='utf-8').read()
i = js.find('adminPerson')
print(js[i-600:i+1400])
PY
echo DONE
