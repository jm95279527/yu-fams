#!/bin/bash
set -e
API=http://127.0.0.1:89
TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 恢复前数据量 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select count(*) from assets; select count(*) from sys_menu; select count(*) from sys_config;" 2>/dev/null

echo "=== 导入备份（上传 zip） ==="
curl -s -X POST "$API/dataBackup/upload" -H "token: $TOKEN" -F "file=@/tmp/dl_backup.zip"; echo
curl -s "$API/dataBackup/list" -H "token: $TOKEN" | python3 -c 'import sys,json;d=json.load(sys.stdin);print([(x["name"],x["typeText"]) for x in d["data"]])'

IMPORT_NAME=$(ls -t /opt/yu-fams/Yu-FAMS-SpringBoot-master/backup/backup_*_import.zip | head -n 1 | xargs basename)
echo "IMPORT_NAME=$IMPORT_NAME"

echo "=== 执行恢复 ==="
START=$(date +%s)
curl -s -X POST "$API/dataBackup/restore?name=$IMPORT_NAME" -H "token: $TOKEN" | python3 -m json.tool
echo "elapsed=$(( $(date +%s) - START ))s"

echo "=== 恢复后数据量 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select count(*) from assets; select count(*) from sys_menu; select count(*) from sys_config; select count(*) from sys_menu where path='/dataBackup';" 2>/dev/null

echo "=== 恢复后配置（应保持） ==="
curl -s "$API/dataBackup/config" -H "token: $TOKEN"; echo

echo "=== 备份列表 ==="
curl -s "$API/dataBackup/list" -H "token: $TOKEN" | python3 -c 'import sys,json;d=json.load(sys.stdin);print([(x["name"],x["typeText"]) for x in d["data"]])'

echo "=== 文件目录 ==="
ls -d /opt/yu-fams/Yu-FAMS-SpringBoot-master/files* 2>/dev/null
ls /opt/yu-fams/Yu-FAMS-SpringBoot-master/files | wc -l

echo "=== 服务状态 ==="
systemctl is-active yufams
echo VERIFY_RESTORE_DONE
