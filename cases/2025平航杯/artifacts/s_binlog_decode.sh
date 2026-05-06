#!/bin/bash
S=/mnt/server
OUT=/tmp/binlog_decoded
sudo mkdir -p $OUT
sudo chown $USER $OUT

echo '=== Decode all binlogs ==='
for f in $S/www/server/data/mysql-bin.0000*; do
    base=$(basename $f)
    echo "## decoding $base ($(sudo stat -c%s $f) bytes)"
    sudo mysqlbinlog --base64-output=DECODE-ROWS -v --skip-gtids "$f" > $OUT/$base.sql 2>$OUT/$base.err
    ls -la $OUT/$base.sql 2>&1
done

echo
echo '=== Total decoded SQL size ==='
ls -la $OUT/

echo
echo '=== Tables seen in binlogs ==='
grep -hoE 'INTO \`?[a-zA-Z_0-9@]+\`?' $OUT/*.sql 2>/dev/null | sort -u | head -30
echo
echo '=== Total INSERT INTO tp_order count ==='
grep -hcE 'INSERT INTO \`?tp_order\`?' $OUT/*.sql 2>/dev/null
echo '-- Sample tp_order INSERT --'
grep -hE 'INSERT INTO \`?tp_order\`? ' $OUT/*.sql 2>/dev/null | head -3