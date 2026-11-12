#!/bin/bash
for f in /tmp/photo_a.jpg /tmp/photo_d.jpg /tmp/photo_e.jpg /tmp/photo_f.jpg /tmp/photo_g.jpg /tmp/photo_h.jpg /tmp/photo_i.jpg; do
  [ -f "$f" ] || continue
  printf '%-18s ' "$(basename $f)"
  curl -s -o /tmp/resp.json -w 'http=%{http_code} time=%{time_total}s ' -X POST http://127.0.0.1:88/api/qr/decode -F "file=@$f"
  head -c 130 /tmp/resp.json; echo
done
echo '--- 普通资产二维码 ---'
curl -s -X POST http://127.0.0.1:88/api/qr/decode -F 'file=@/tmp/asset_qr.png'; echo
echo '--- 非二维码图片 ---'
curl -s -X POST http://127.0.0.1:88/api/qr/decode -F 'file=@/tmp/bad.jpg'; echo
