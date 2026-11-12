#!/bin/bash
echo "=== yufams.service 单元文件 ==="
systemctl cat yufams.service 2>/dev/null
echo "=== 状态 ==="
systemctl status yufams.service --no-pager 2>/dev/null | head -15
echo "=== 是否开机自启 ==="
systemctl is-enabled yufams.service 2>/dev/null
echo DONE
