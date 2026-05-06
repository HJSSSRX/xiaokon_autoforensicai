#!/bin/bash
F=/tmp/binlog_decoded/mysql-bin.000026.sql

echo '=== Tables ==='
grep -hoE 'INSERT INTO `[a-zA-Z_0-9]+`' $F | sort | uniq -c | sort -rn | head -30

echo
echo '=== tp_order count ==='
grep -F 'INSERT INTO `tp_order`' $F | wc -l

echo
echo '=== tp_order_goods count ==='
grep -F 'INSERT INTO `tp_order_goods`' $F | wc -l

echo
echo '=== tp_users count ==='
grep -F 'INSERT INTO `tp_users`' $F | wc -l

echo
echo '=== first/last order add_time (col 30, unix ts) ==='
grep -F 'INSERT INTO `tp_order`' $F | head -1 | grep -oE "'[0-9]{10}'" | head
grep -F 'INSERT INTO `tp_order`' $F | tail -1 | grep -oE "'[0-9]{10}'" | head