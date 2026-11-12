#!/bin/bash
LOG=$(ls -t /opt/yu-fams/logs/*.log 2>/dev/null | head -1)
echo "LOG=$LOG"
tail -80 "$LOG"
