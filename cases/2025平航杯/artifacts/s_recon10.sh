#!/bin/bash
S=/mnt/server

echo '=== Find gd.so for both PHP versions ==='
sudo find $S/www/server/php -name 'gd*' -type f 2>/dev/null | head -10

echo
echo '=== PHP 7.4 GD module strings ==='
GD74=$(sudo find $S/www/server/php/74 -name 'gd.so' 2>/dev/null | head -1)
echo "## $GD74"
sudo strings "$GD74" 2>/dev/null | grep -iE 'gd version|2\.[0-9]+\.[0-9]+|^bundled|GD library version' | head -20

echo
echo '=== PHP 5.6 GD module strings ==='
GD56=$(sudo find $S/www/server/php/56 -name 'gd.so' 2>/dev/null | head -1)
echo "## $GD56"
sudo strings "$GD56" 2>/dev/null | grep -iE 'gd version|2\.[0-9]+\.[0-9]+|^bundled' | head -20

echo
echo '=== TPshop server info page (admin/Index/server_info.php) ==='
sudo find $S/www/wwwroot/www.tpshop.com/application/admin -name '*Server*' -o -name '*server*' 2>/dev/null | head
sudo grep -rln 'GD\|gd_info' $S/www/wwwroot/www.tpshop.com/application/admin 2>/dev/null | head -5
sudo grep -rE 'gd_info|GD_VERSION|GD Library' $S/www/wwwroot/www.tpshop.com/application 2>/dev/null | head -10

echo
echo '=== PHP version active for tpshop ==='
ls -la $S/etc/init.d/php-fpm* 2>/dev/null
ls $S/www/server/php/ 2>&1
sudo cat $S/www/server/nginx/conf/vhost/www.tpshop.com.conf 2>/dev/null | grep -E 'fastcgi|php' | head -5

echo
echo '=== PHP 74 freetype/gd in extension dir ==='
ls $S/www/server/php/74/lib/php/extensions/ 2>/dev/null