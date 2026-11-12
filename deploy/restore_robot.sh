#!/bin/bash
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e"
echo "=== 审计日志里用户自己添加的机器人（完整参数）==="
mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT CONCAT(id,'|',create_time,'|',params) FROM audit_log WHERE uri='/robotConfig/add' AND (params LIKE '%资产提醒%' OR params LIKE '%企微资产%') ORDER BY id;" 2>/dev/null > /tmp/rbots.txt
cat /tmp/rbots.txt

python3 - <<'PY'
import json
def esc(s):
    if s is None:
        return "NULL"
    return "'" + s.replace("\\", "\\\\").replace("'", "''") + "'"

sqls = []
for line in open('/tmp/rbots.txt', encoding='utf-8'):
    line = line.strip()
    if not line or '|' not in line:
        continue
    _id, ts, params = line.split('|', 2)
    try:
        d = json.loads(params)
    except Exception as e:
        print('  解析失败:', e, params[:80])
        continue
    name = d.get('name')
    url = d.get('webhookUrl')
    print('  发现:', name, '|', url, '| create=', ts)
    # 只恢复用户命名的机器人（跳过我的 E2E 临时机器人）
    if name and ('资产提醒' in name or '企微资产' in name):
        sqls.append(
            "INSERT INTO robot_config (name,type,webhook_url,secret,enabled,remark,create_time,update_time) "
            "VALUES (%s,'wechat',%s,%s,%s,%s,NOW(),NOW());" % (
                esc(name), esc(url), esc(d.get('secret')),
                '1' if d.get('enabled', True) else '0', esc(d.get('remark'))))
open('/tmp/restore_robot.sql', 'w', encoding='utf-8').write("\n".join(sqls))
print('  将恢复', len(sqls), '条')
PY

echo "=== 执行恢复 ==="
if [ -s /tmp/restore_robot.sql ]; then
  mysql -uroot -pYOUR_DB_PASSWORD xm-assets < /tmp/restore_robot.sql
  echo "恢复完成"
else
  echo "无可恢复内容"
fi
echo "=== 恢复后 robot_config ==="
$M "SELECT CONCAT('  id=',id,' name=',IFNULL(name,''),' enabled=',enabled,' url=',IFNULL(webhook_url,'')) FROM robot_config;" 2>/dev/null
rm -f /tmp/rbots.txt /tmp/restore_robot.sql
echo DONE
