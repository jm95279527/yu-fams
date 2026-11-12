#!/bin/bash
echo "=== 触发一次未映射路径请求 ==="
curl -s -o /dev/null -w "  http=%{http_code}\n" http://127.0.0.1:89/zzz/notexist
sleep 2
echo ""
echo "=== 最近的异常堆栈 ==="
journalctl -u yufams -n 400 --no-pager 2>/dev/null | grep -n -B2 -A 18 'Exception\|错误\|ERROR' | tail -80
echo ""
echo "=== 最近 40 行原始日志 ==="
journalctl -u yufams -n 40 --no-pager 2>/dev/null
echo DIAG_DONE
