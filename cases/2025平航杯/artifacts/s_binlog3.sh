#!/bin/bash
F=/tmp/binlog_decoded/mysql-bin.000026.sql

echo '=== Tables seen ==='
grep -hoE 'INTO \`[a-zA-Z_0-9]+\`' $F | sort -u | head -30

echo
echo '=== Order table count ==='
grep -cE 'INSERT INTO \`tp_order\`' $F

echo
echo '=== tp_order INSERT 第一行结构 ==='
grep -m 1 'INSERT INTO `tp_order`' $F | head -1 | cut -c1-300

echo
echo '=== 订单 add_time 时间范围统计 ==='
# tp_order 表字段顺序很重要 — 需查表结构
echo '-- tp_order CREATE TABLE --'
sudo grep -A 50 'CREATE TABLE.*tp_order\b' /mnt/server/www/wwwroot/www.tpshop.com/backup/www_TPshop_com1.sql | head -50

echo
echo '=== tp_users (S14 注册→首单) ==='
grep -cE 'INSERT INTO \`tp_users\`' $F
echo '-- sample --'
grep -m 1 'INSERT INTO `tp_users`' $F | head -1 | cut -c1-300

echo
echo '=== freight_free (S10) - 每个 INSERT/UPDATE for freight_free key ==='
grep -E 'freight_free' $F | head