#!/bin/bash
WEBROOT=/mnt/server/www/wwwroot
LOGS=/mnt/server/www/wwwlogs
APP=$WEBROOT/www.tpshop.com

echo '=== 查找所有 webshell 特征代码 ==='
sudo grep -rIlE '(eval|assert)\s*\(\s*\$_(POST|GET|REQUEST)|system\s*\(\s*\$_|@\$_(POST|GET|REQUEST)\[' $APP 2>/dev/null

echo
echo '=== 一句话特征 (短文件 + eval/assert) ==='
sudo find $APP -name '*.php' -size -3k -newer $APP/index.html 2>/dev/null | head -20
echo '-- 时间 2022 年新建文件 --'
sudo find $APP -name '*.php' -newer /tmp/dummy 2>/dev/null | xargs sudo stat -c '%Y %n' 2>/dev/null | sort -rn | head -20

echo
echo '=== 后台 admin 上传日志 ==='
sudo grep -E 'upload|Uploa|Picture|\.php' $LOGS/www.tpshop.com.log 2>/dev/null | grep -E 'POST' | head -20

echo
echo '=== Uploads dir suspicious .php ==='
sudo find $APP/public/upload $APP/uploads $APP/Uploads $WEBROOT/192.168.100.100/Uploads -name '*.php' 2>/dev/null

echo
echo '=== TPshop GD version + admin login encrypt ==='
sudo grep -rn 'function encrypt' $APP/common.php $APP/application 2>/dev/null | head
sudo grep -A 5 'function encrypt' $APP/application/common.php 2>/dev/null
sudo grep -rn 'free_postage\|freight\|免运费' $APP/application 2>/dev/null | head -10

echo
echo '=== 配置 store: free postage (S10) ==='
sudo grep -rn 'free_postage\|MIN_GOODS_AMOUNT' $APP/application 2>/dev/null | head -10