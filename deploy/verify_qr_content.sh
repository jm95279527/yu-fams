#!/bin/bash
B=http://127.0.0.1:89
AID=$(mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT id FROM assets ORDER BY id DESC LIMIT 1;" 2>/dev/null)
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
curl -s -o /tmp/q.zip "$B/assets/qrcode/batch?ids=$AID&token=$TOK"
rm -rf /tmp/qz && mkdir -p /tmp/qz && unzip -o -q /tmp/q.zip -d /tmp/qz
PNG=$(ls /tmp/qz/*.png | head -1)
EXPECT="http://YOUR_SERVER_IP:88/scan/$AID"
OLD="http://YOUR_SERVER_IP:89/scan/$AID"
curl -s -o /tmp/expect.png --get --data-urlencode "text=$EXPECT" --data-urlencode "size=300" "$B/qr/png"
curl -s -o /tmp/old.png    --get --data-urlencode "text=$OLD"    --data-urlencode "size=300" "$B/qr/png"
echo "zip内 : $(md5sum "$PNG" | cut -d' ' -f1)  $(stat -c%s "$PNG")B"
echo "期望88: $(md5sum /tmp/expect.png | cut -d' ' -f1)  $(stat -c%s /tmp/expect.png)B   <- $EXPECT"
echo "旧89  : $(md5sum /tmp/old.png | cut -d' ' -f1)  $(stat -c%s /tmp/old.png)B   <- $OLD"
if cmp -s "$PNG" /tmp/expect.png; then echo "结论: 二维码内容 == 期望的前端 :88 链接 ✓"; else echo "结论: 与期望不一致 ✗"; fi
if cmp -s "$PNG" /tmp/old.png; then echo "（仍与旧的 :89 链接相同，未生效）"; else echo "（已不同于旧的 :89 链接，说明内容已改变）"; fi
echo DONE
