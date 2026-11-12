#!/bin/bash
B=http://127.0.0.1:89
M="mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N"
TOK=$(curl -s -X POST $B/login -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123","role":"ADMIN"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["token"])')
echo "TOKLEN=${#TOK}"

echo "=== 1) 现存员工（确认不是我的测试数据）==="
$M -e "select concat('  id=',s.id,' | 工号=',ifnull(s.emp_no,'-'),' | 姓名=',s.name,' | 账号=',s.username,' | 部门=',ifnull(d.name,'-'),' | 状态=',ifnull(s.status,'-'),' | 创建/入职=',ifnull(s.entry_date,'-')) from staff s left join department d on s.department_id=d.id order by s.id"

echo ""
echo "=== 2) 员工修改结果复核（修掉脚本里 name 歧义的问题）==="
$M -e "select concat('  id=',s.id,' | 姓名=',s.name,' | 职位=',ifnull(s.position,'-'),' | 电话=',ifnull(s.phone,'-')) from staff s where s.username='zzclean_a'"
echo "  （zzclean_a 应已被清理，上面无输出即正常）"

echo ""
echo "=== 3) 未映射路径 + 无 token 的 HTTP 状态对照 ==="
for u in /integration/wechat/authUrl /zzz/notexist /assetsReceive/delete/999901; do
  printf "  无token %-34s -> %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$B$u")"
done
for u in /integration/wechat/authUrl /zzz/notexist; do
  printf "  有token %-34s -> %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' "$B$u" -H "token: $TOK")"
done
echo "  -- 无 token 调已映射接口的返回体 --"
curl -s "$B/assets/selectPage?pageNum=1&pageSize=1"; echo

echo ""
echo "=== 4) 集成相关数据库对象仍在（未误删数据）==="
for t in wechat_work_config dingtalk_config third_party_user; do
  echo "  $t = $($M -e "select count(*) from $t" 2>/dev/null) 行"
done
echo "  wechat_work_config.corp_id = $($M -e "select corp_id from wechat_work_config limit 1" 2>/dev/null)"
echo CHECK2_DONE
