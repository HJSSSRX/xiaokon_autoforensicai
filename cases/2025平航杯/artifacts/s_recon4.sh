#!/bin/bash
S=/mnt/server
B=/mnt/server_boot

echo '=== /boot kernel (in /dev/nbd0p1) ==='
ls $B/ 2>&1 | head -20
ls $B/vmlinuz-* 2>&1

echo
echo '=== nginx vhost configs ==='
find $S/www/server/nginx -name '*.conf' -path '*vhost*' 2>/dev/null
ls $S/www/server/panel/vhost/ 2>&1
find $S/www -name '*.conf' 2>/dev/null | head -20

echo
echo '=== nginx main conf ==='
cat $S/www/server/nginx/conf/nginx.conf 2>/dev/null | head -30

echo
echo '=== access.log first/last + 攻击 IP ==='
sudo head -3 $S/www/wwwlogs/access.log 2>&1
echo '...'
sudo tail -3 $S/www/wwwlogs/access.log 2>&1
echo
echo '-- POST 请求统计（疑似上传木马）--'
sudo grep -E 'POST .*\.(php|jsp)' $S/www/wwwlogs/access.log 2>&1 | head -20
echo
echo '-- PUT / 404 / 5xx 关键 --'
sudo grep -E 'PUT |/admin|webshell|shell\.php|cmd\.php|eval' $S/www/wwwlogs/*.log 2>&1 | head -20

echo
echo '=== tpshop application 结构 ==='
ls $S/www/wwwroot/www.tpshop.com/application/ 2>&1
echo
echo '-- backup 目录 --'
ls -la $S/www/wwwroot/www.tpshop.com/backup/ 2>&1 | head -20