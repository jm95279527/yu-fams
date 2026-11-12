#!/bin/bash
echo "=== restart script ==="
cat /tmp/restart_backend.sh 2>/dev/null
echo "=== nohup.out anywhere recent ==="
find / -name "nohup.out" 2>/dev/null | head
echo "=== journalctl for java ==="
journalctl -u springboot --no-pager -n 40 2>/dev/null || echo "no systemd unit"
echo "=== stdout of PID 2472292 ==="
ls -l /proc/2472292/fd/1 2>/dev/null
