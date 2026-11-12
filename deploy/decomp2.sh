#!/bin/bash
cd /tmp/hutoolx
javap -p -c cn/hutool/poi/excel/ExcelWriter.class > /tmp/excelwriter.txt 2>&1
echo "== methods =="
grep -n "writeRow\|writeHeader\|private.*write" /tmp/excelwriter.txt | head -20
echo "== onlyAlias context =="
grep -n "onlyAlias" /tmp/excelwriter.txt | head
echo DONE
