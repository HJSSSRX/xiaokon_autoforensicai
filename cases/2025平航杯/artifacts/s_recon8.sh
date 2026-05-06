#!/bin/bash
APP=/mnt/server/www/wwwroot/www.tpshop.com

echo '=== peiqi.php (一句话木马) ==='
sudo stat $APP/peiqi.php 2>&1 | grep -E 'Size|Modify|Birth'
echo '--- content ---'
sudo cat $APP/peiqi.php
echo
echo '--- sha256 大写 ---'
sudo sha256sum $APP/peiqi.php | awk '{print toupper($1)}'

echo
echo '=== install/666.php ==='
sudo stat $APP/install/666.php 2>&1 | grep -E 'Size|Modify|Birth'
sudo cat $APP/install/666.php
echo
sudo sha256sum $APP/install/666.php

echo
echo '=== install/hl.php ==='
sudo stat $APP/install/hl.php 2>&1 | grep -E 'Size|Modify|Birth'
sudo cat $APP/install/hl.php
echo
sudo sha256sum $APP/install/hl.php

echo
echo '=== encrypt() function source ==='
sudo sed -n '1,60p' $APP/application/function.php

echo
echo '=== TPshop release / version ==='
sudo grep -rE 'TPSHOP|tp-shop|\sV[0-9]+\.[0-9]+' $APP/README.md $APP/LICENSE.txt 2>/dev/null | head
sudo cat $APP/build.php 2>/dev/null | head
sudo find $APP -name 'changelog*' -o -name 'CHANGELOG*' -o -name 'VERSION*' 2>/dev/null | head -5

echo
echo '=== POST 上传 peiqi.php 痕迹 (是否有 admin 登录) ==='
sudo grep -E 'peiqi|666\.php|hl\.php' /mnt/server/www/wwwlogs/www.tpshop.com.log 2>&1 | head -30