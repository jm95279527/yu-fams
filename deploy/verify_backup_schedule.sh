#!/bin/bash
set -e
API=http://127.0.0.1:89
BK=/opt/yu-fams/Yu-FAMS-SpringBoot-master/backup
TOKEN=$(curl -s -X POST $API/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')

MANUAL=$(ls -t $BK/backup_*_manual.zip | head -n 1)
cp "$MANUAL" "$BK/backup_20200101_000000_auto.zip"
echo "fake auto created: $(basename $BK/backup_20200101_000000_auto.zip)"

NEXT=$(date -d '+1 minute' +%H:%M)
echo "server now=$(date '+%H:%M:%S') next=$NEXT"

curl -s -X POST "$API/dataBackup/config" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"enabled\":true,\"time\":\"$NEXT\",\"keepCount\":1}"; echo

echo "=== 等待定时备份触发 ==="
NEW_AUTO=""
for i in $(seq 1 18); do
  sleep 10
  NEW_AUTO=$(ls -t $BK/backup_*_auto.zip 2>/dev/null | grep -v '20200101_000000' | head -n 1 || true)
  if [ -n "$NEW_AUTO" ]; then
    echo "auto backup created: $(basename $NEW_AUTO)"
    break
  fi
done

echo "=== 配置 ==="
curl -s "$API/dataBackup/config" -H "token: $TOKEN"; echo

echo "=== auto 备份数量（保留份数=1，旧文件应被清理） ==="
ls -1 $BK/backup_*_auto.zip 2>/dev/null | sed 's|.*/||'
echo "count=$(ls -1 $BK/backup_*_auto.zip 2>/dev/null | wc -l)"

echo "=== 关闭定时备份 ==="
curl -s -X POST "$API/dataBackup/config" -H "token: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"enabled":false,"time":"02:00","keepCount":7}'; echo
echo SCHEDULE_TEST_DONE
