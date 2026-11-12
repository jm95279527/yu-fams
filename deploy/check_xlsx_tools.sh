#!/bin/bash
echo "=== python3 ==="
python3 -V 2>&1
echo "=== 是否有 openpyxl ==="
python3 -c "import openpyxl; print('openpyxl OK', openpyxl.__version__)" 2>&1 | head -3
echo "=== 是否有 xlwt ==="
python3 -c "import xlwt; print('xlwt OK')" 2>&1 | head -3
echo "=== 是否有 pandas ==="
python3 -c "import pandas; print('pandas OK')" 2>&1 | head -3
echo "=== 项目里有没有 poi / hutool ==="
ls /root/.m2/repository/org/apache/poi/poi-ooxml/*/ 2>/dev/null | head -5
find /root/.m2/repository -name "hutool-all*.jar" 2>/dev/null | head -3
echo "=== jar 内是否含 POI ==="
unzip -l /opt/yu-fams/Yu-FAMS-SpringBoot-master/target/springboot-0.0.1-SNAPSHOT.jar 2>/dev/null | grep -c "poi-ooxml"
echo DONE
