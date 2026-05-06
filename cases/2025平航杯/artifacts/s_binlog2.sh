#!/bin/bash
S=/mnt/server
OUT=/tmp/binlog_decoded
sudo rm -f $OUT/*
sudo chown $USER $OUT

for f in $S/www/server/data/mysql-bin.0000*; do
    base=$(basename $f)
    sudo mysqlbinlog --base64-output=DECODE-ROWS -v "$f" > $OUT/$base.sql 2>/dev/null
done

echo '=== sizes ==='
ls -la $OUT/*.sql
echo
echo '=== Tables in binlog (write events) ==='
grep -hoE '### INSERT INTO \`?[^\`]+\`?\.\`?[a-zA-Z_0-9]+\`?' $OUT/*.sql 2>/dev/null | sort -u | head -30

echo
echo '=== INSERT INTO tp_order rows ==='
grep -cE '### INSERT INTO \`tpshop2.0\`.\`tp_order\`' $OUT/*.sql
echo
grep -hcE '^### INSERT INTO ' $OUT/*.sql | head

echo
echo '=== sample order INSERT (first 50 lines around tp_order) ==='
grep -A 30 -m 1 'INSERT INTO `tpshop2.0`.`tp_order`' $OUT/*.sql | head -50

echo
echo '=== freight_free / shopping config ==='
grep -B1 -A3 'freight_free\|shopping' $OUT/*.sql 2>/dev/null | head -30