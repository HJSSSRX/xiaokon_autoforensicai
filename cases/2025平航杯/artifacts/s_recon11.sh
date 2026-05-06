#!/bin/bash
S=/mnt/server
APP=$S/www/wwwroot/www.tpshop.com

echo '=== welcome.html - server info display ==='
sudo grep -n 'gd\|GD\|version\|系统' $APP/application/admin/view/index/welcome.html 2>/dev/null | head -20

echo
echo '=== Index.php gd_info usage ==='
sudo grep -B2 -A 15 'gd_info' $APP/application/admin/controller/Index.php

echo
echo '=== PHP74 gd extension ==='
sudo find $S/www/server/php/74/lib -name '*gd*' 2>/dev/null
sudo find $S/www/server/php/56/lib -name '*gd*' 2>/dev/null

echo
echo '=== PHP74 binary GD version info ==='
PHP74=$S/www/server/php/74/bin/php
sudo strings -n 6 "$PHP74" | grep -E '^[0-9]\.[0-9]\.[0-9]' | head -5
echo '-- find "GD library" or "gd 2." in any binary --'
sudo grep -aoE 'gd 2\.[0-9]+\.[0-9]+|GD library version[^\n]+|GDVersion[^\n]+' $S/www/server/php/74/bin/php $S/www/server/php/74/sbin/* 2>/dev/null | head -10

echo
echo '=== Check if gd compiled with --with-gd=internal (bundled) ==='
sudo grep -aoE 'bundled \(2\.[0-9]+\.[0-9]+ compatible\)|--with-gd' $S/www/server/php/74/bin/php* 2>/dev/null | head -5

echo
echo '=== Check libgd shared lib ==='
sudo find $S/usr -name 'libgd*' 2>/dev/null | head -5
sudo find $S/lib64 -name 'libgd*' 2>/dev/null | head -5