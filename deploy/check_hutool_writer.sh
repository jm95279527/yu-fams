#!/bin/bash
CP=$(cat /tmp/cp.txt)
javap -cp "$CP" cn.hutool.poi.excel.ExcelWriter | grep -i 'writeHeadRow\|write(' | head -n 12
