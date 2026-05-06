#!/bin/bash
APP=/mnt/server/www/wwwroot/www.tpshop.com
LOGS=/mnt/server/www/wwwlogs

echo '=== encrypt() 函数 ==='
sudo sed -n '25,55p' $APP/application/function.php

echo
echo '=== TPshop config / version ==='
sudo grep -E 'TPSHOP_VERSION|VERSION|version' $APP/application/common.php 2>/dev/null | head -10
sudo grep -E 'tpshop' $APP/README.md 2>/dev/null | head -5
sudo cat $APP/application/extra/tpshop.php 2>/dev/null | head -20

echo
echo '=== 数据库备份 head ==='
sudo grep -E 'admin|password|tp_admin|tp_config|freight_free' $APP/backup/www_TPshop_com1.sql 2>/dev/null | head -30

echo
echo '=== access.log 攻击者 IP 上传 webshell 痕迹 ==='
sudo grep -E 'POST.*\.(php|htaccess) HTTP|upload.*\.(php|jpg)|FastPwds|Picture|edit_pic|ueditor' $LOGS/www.tpshop.com.log 2>&1 | grep -vE 'install/|phpmyadmin|panel' | head -30

echo
echo '=== 找 backup 时间为 2022-03-04 后的 .php 文件（攻击者写入）==='
sudo find $APP -name '*.php' -newermt 2022-03-03 ! -newermt 2022-03-10 2>/dev/null | head -30