#!/bin/bash
cd /tmp
rm -rf hutoolx && mkdir hutoolx && cd hutoolx
unzip -o -q /root/.m2/repository/cn/hutool/hutool-all/5.8.22/hutool-all-5.8.22.jar 'cn/hutool/poi/excel/ExcelWriter.class' 'cn/hutool/poi/excel/ExcelBase.class' 'cn/hutool/poi/excel/CellUtil.class'
echo "===== writeRow(Map) / onlyAlias usage in ExcelBase ====="
javap -p -c cn/hutool/poi/excel/ExcelBase.class 2>/dev/null | grep -n "onlyAlias\|AliasMap\|getFieldNames\|HeaderAlias" | head -30
echo "===== CellUtil alias methods ====="
javap -p cn/hutool/poi/excel/CellUtil.class 2>/dev/null | grep -i alias
echo DONE
