#!/bin/bash
# xm-assets 每日备份，保留 7 天
DIR=/opt/yu-fams/backup
mkdir -p $DIR
F=$DIR/xm-assets_$(date +%Y%m%d_%H%M).sql.gz
if mysqldump -uroot xm-assets --single-transaction --routines --triggers 2>/dev/null | gzip > "$F"; then
  if [ -s "$F" ] && gunzip -t "$F" 2>/dev/null; then
    echo "$(date '+%F %T') OK $F $(stat -c%s $F)bytes"
  else
    echo "$(date '+%F %T') CORRUPT $F"
    rm -f "$F"
  fi
else
  echo "$(date '+%F %T') DUMP_FAIL $F"
  rm -f "$F"
fi
find $DIR -name 'xm-assets_*.sql.gz' -mtime +7 -delete
