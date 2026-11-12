#!/bin/bash
set -e
API=http://127.0.0.1:89
TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

echo "=== 菜单 ==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "select id,parent_id,name,path,api from sys_menu where path='/dataBackup';" 2>/dev/null

echo "=== 配置 ==="
curl -s "$API/dataBackup/config" -H "token: $TOKEN"; echo

echo "=== 立即备份 ==="
curl -s -X POST "$API/dataBackup/create" -H "token: $TOKEN" | python3 -m json.tool

echo "=== 列表 ==="
curl -s "$API/dataBackup/list" -H "token: $TOKEN" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d["code"],[(x["name"],x["sizeText"]) for x in d["data"]])'

echo "=== 备份目录 ==="
ls -lh /opt/yu-fams/Yu-FAMS-SpringBoot-master/backup/ | tail -n 8

echo "=== 压缩包内容 ==="
BK=$(ls -t /opt/yu-fams/Yu-FAMS-SpringBoot-master/backup/backup_*_manual.zip | head -n 1)
python3 - "$BK" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
names = z.namelist()
print('entries=', len(names))
print('db.sql=', 'db.sql' in names, 'manifest=', 'manifest.json' in names)
print('files entries=', len([n for n in names if n.startswith('files/')]))
PY

echo "=== 通过 88 下载 ==="
NAME=$(basename "$BK")
curl -s -o /tmp/dl_backup.zip -w 'http=%{http_code} size=%{size_download}\n' \
  "http://127.0.0.1:88/api/dataBackup/download?name=$NAME&token=$TOKEN"
python3 - <<'PY'
import zipfile
z = zipfile.ZipFile('/tmp/dl_backup.zip')
print('download zip ok, db.sql=', 'db.sql' in z.namelist())
PY
echo VERIFY_BACKUP_DONE
