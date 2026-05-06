#!/bin/bash
S=/mnt/server

echo '=== /boot kernel ==='
ls $S/boot/vmlinuz-* 2>&1
ls $S/boot/grub2/ 2>&1 | head -10
grep -E '^menuentry|set default' $S/boot/grub2/grub.cfg 2>/dev/null | head -10

echo
echo '=== www tree ==='
ls $S/www/wwwroot/ 2>&1
echo '--- panel ---'
ls $S/www/server/ 2>&1
ls $S/www/server/panel/ 2>&1 | head -15

echo
echo '=== mysql data ==='
ls $S/www/server/data/ 2>&1 | head -20
ls $S/www/server/mysql/ 2>&1 | head -10

echo
echo '=== nginx config ==='
ls $S/www/server/nginx/conf/ 2>&1 | head
ls $S/www/server/nginx/conf/vhost/ 2>&1
cat $S/www/server/nginx/conf/vhost/*.conf 2>/dev/null | head -100

echo
echo '=== wwwlogs ==='
ls $S/www/wwwlogs/ 2>&1 | head -20

echo
echo '=== wwwroot detail ==='
for d in $S/www/wwwroot/*/; do
    echo "-- $d --"
    ls "$d" 2>&1 | head -10
done