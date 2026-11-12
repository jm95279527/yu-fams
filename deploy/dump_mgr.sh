#!/bin/bash
python3 - <<'PY'
js = open('/www/wwwroot/yufams/js/28.5bfc8e64.js', encoding='utf-8').read()
i = js.find('menuTree')
print(js[i-900:i+900])
PY
echo DONE
