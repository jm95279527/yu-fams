#!/bin/bash
B=http://127.0.0.1:89
TOK=$(curl -s "$B/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123","role":"ADMIN"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
AID=$(mysql -uroot -pYOUR_DB_PASSWORD xm-assets -N -e "SELECT id FROM assets ORDER BY id DESC LIMIT 1;" 2>/dev/null)
echo "asset_id=$AID"
echo "=== 1) 导出仍含二维码链接 ==="
curl -s -o /tmp/e.xlsx "$B/assets/export?token=$TOK"
python3 - <<'PY'
import zipfile, xml.etree.ElementTree as ET
NS='{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
z=zipfile.ZipFile('/tmp/e.xlsx')
ss=[]
if 'xl/sharedStrings.xml' in z.namelist():
    r=ET.fromstring(z.read('xl/sharedStrings.xml'))
    for si in r.findall(NS+'si'): ss.append(''.join(t.text or '' for t in si.iter(NS+'t')))
sh=ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
rows=sh.find(NS+'sheetData').findall(NS+'row')
def cells(rw):
    out=[]
    for c in rw.findall(NS+'c'):
        v=c.find(NS+'v'); t='' if v is None else v.text
        if c.get('t')=='s' and t not in (None,''): t=ss[int(t)]
        out.append('' if t is None else t)
    return out
h=cells(rows[0])
print('表头(%d): 末列=%s' % (len(h), h[-1]))
print('末列值=%s' % cells(rows[1])[-1])
PY
echo "=== 2) 批量二维码 zip ==="
curl -s -o /tmp/q.zip "$B/assets/qrcode/batch?ids=$AID&token=$TOK"
ls -l /tmp/q.zip
unzip -l /tmp/q.zip
rm -rf /tmp/qz && mkdir -p /tmp/qz && unzip -o -q /tmp/q.zip -d /tmp/qz
PNG=$(ls /tmp/qz/*.png 2>/dev/null | head -1)
echo "png=$PNG"
head -c 4 "$PNG" | xxd -p
echo "=== 3) 尝试解码二维码内容 ==="
python3 - "$PNG" <<'PY'
import sys
p=sys.argv[1]
try:
    import cv2
    d=cv2.QRCodeDetector()
    data,_,_=d.detectAndDecode(cv2.imread(p))
    print('cv2 decoded:', repr(data))
    raise SystemExit
except ImportError:
    print('cv2 不可用')
except Exception as e:
    print('cv2 err', e)
try:
    from pyzbar.pyzbar import decode
    from PIL import Image
    print('pyzbar decoded:', [o.data.decode() for o in decode(Image.open(p))])
except ImportError:
    print('pyzbar 不可用')
except Exception as e:
    print('pyzbar err', e)
PY
echo "=== 4) 期望值 ==="
echo "http://YOUR_SERVER_IP:88/scan/$AID"
echo DONE
