#!/bin/bash
python3 - <<'PY'
js = open('/www/wwwroot/yufams/js/28.5bfc8e64.js', encoding='utf-8').read()
i = js.find('name:"Manager"')
print(js[i:i+1500])
PY
echo DONE
