#!/bin/bash
echo "=== sharedStrings.xml (前 1500 字节) ==="
unzip -p /tmp/a.xlsx xl/sharedStrings.xml 2>/dev/null | head -c 1500
echo
echo "=== sheet1.xml (前 3000 字节) ==="
unzip -p /tmp/a.xlsx xl/worksheets/sheet1.xml 2>/dev/null | head -c 3000
echo
echo "=== 各部件大小 ==="
unzip -l /tmp/a.xlsx
echo DONE
