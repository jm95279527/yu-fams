#!/bin/bash
journalctl -u yufams -n 60 --no-pager | grep -iE "exception|error|caused|at com.example" | tail -40
echo "---- 最近请求日志 ----"
journalctl -u yufams -n 30 --no-pager | tail -20
