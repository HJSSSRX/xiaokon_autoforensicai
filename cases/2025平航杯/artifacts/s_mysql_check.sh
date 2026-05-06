#!/bin/bash
S=/mnt/server

echo '=== Check mysql tools in WSL ==='
which mysql mysqld mariadbd 2>/dev/null

echo
echo '=== mysql data directory inspection ==='
ls $S/www/server/data/tpshop2@002e0/ 2>&1 | head -20
echo
echo '-- mysql server version (from binary) --'
sudo strings $S/www/server/mysql/bin/mysqld 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | head -3
sudo $S/www/server/mysql/bin/mysqld --version 2>&1 | head

echo
echo '=== Try copy data and launch mysql ==='
# Check space
df -h /tmp /var/lib/mysql 2>&1 | head -5