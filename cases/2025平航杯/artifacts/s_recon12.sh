#!/bin/bash
S=/mnt/server
echo '=== nginx vhost configs ==='
sudo find $S/www/server/panel/vhost -type f 2>/dev/null
ls $S/www/server/panel/vhost/ 2>&1 | head
echo
echo '-- nginx site configs --'
sudo find $S/www/server/nginx/conf -name '*.conf' -path '*vhost*' -o -name '*.conf' -path '*site*' 2>/dev/null | head
sudo cat $S/www/server/panel/vhost/nginx/www.tpshop.com.conf 2>/dev/null | head -30
sudo cat $S/www/server/panel/vhost/nginx/192.168.100.100.conf 2>/dev/null | head -30
echo
echo '-- enable-php conf --'
sudo grep -E 'fastcgi_pass|enable-php' $S/www/server/panel/vhost/nginx/*.conf 2>/dev/null

echo
echo '=== PHP 5.6 GD bundled version ==='
sudo grep -aoE 'bundled \(2\.[0-9]+\.[0-9]+ compatible\)' $S/www/server/php/56/bin/php 2>/dev/null | head -1

echo
echo '=== TPshop version in config ==='
sudo grep -rE 'TPSHOP_VERSION|tpshop_version|\sVERSION\s*=' $S/www/wwwroot/www.tpshop.com/application/extra 2>/dev/null
sudo cat $S/www/wwwroot/www.tpshop.com/application/extra/tpshop.php 2>/dev/null | head -20

echo
echo '=== S09 mysql data 数据库列表 ==='
ls $S/www/server/data/ 2>&1 | grep -vE 'ib_|auto|mysql-bin|mysql-slow|localhost' | head -10