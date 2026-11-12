#!/bin/bash
echo "== file type =="
file -b /tmp/rf_inv_rpt.xlsx
echo "== internal field hits =="
grep -rao 'taskId\|departmentId\|scannerId\|dealUserId\|isExtra' /tmp/rf_rptx | sort | uniq -c
echo "== sharedStrings content =="
python3 - <<'PY'
import re
xml = open('/tmp/rf_rptx/xl/sharedStrings.xml', encoding='utf-8').read()
texts = re.findall(r'<t[^>]*>(.*?)</t>', xml, re.S)
for t in texts[:40]:
    print(repr(t))
PY
echo DONE
