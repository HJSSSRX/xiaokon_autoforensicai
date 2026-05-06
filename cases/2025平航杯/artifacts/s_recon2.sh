#!/bin/bash
S=/mnt/server

echo '=== S01 最早开机时间 ==='
sudo last -f $S/var/log/wtmp 2>&1 | tail -10
echo '-- /var/log/messages 最早行 --'
ls -la $S/var/log/messages* 2>&1 | head -5
sudo head -1 $S/var/log/messages-* 2>/dev/null | head -10

echo
echo '=== /var/log structure ==='
ls $S/var/log/ 2>&1 | head -30

echo
echo '=== 网站 www ==='
ls -la $S/www/ 2>&1 | head -30
ls -la $S/home/www/ 2>&1 | head -10

echo
echo '=== Nginx / Apache ==='
ls $S/etc/nginx/ 2>&1 | head
ls $S/etc/httpd/ 2>&1 | head
find $S/etc/nginx -name '*.conf' 2>/dev/null | head -5

echo
echo '=== /root/log ==='
ls -la $S/root/log/ 2>&1
echo '-- nano dir --'
ls -la $S/root/nano/ 2>&1
echo '-- sudo dir --'
ls -la $S/root/sudo/ 2>&1

echo
echo '=== bash_history (root) ==='
sudo cat $S/root/.bash_history 2>&1 | head -100