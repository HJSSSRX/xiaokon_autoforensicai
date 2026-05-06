#!/bin/bash
APP=/mnt/server/www/wwwroot/www.tpshop.com/application

echo '=== command.php (疑似 webshell) ==='
sudo stat $APP/command.php 2>&1 | grep -E 'Size|Modify|Birth'
echo '--- content ---'
sudo cat $APP/command.php

echo
echo '=== result.txt (RDP 扫描结果?) ==='
sudo head -100 $APP/result.txt 2>&1

echo
echo '=== FastPwds.txt 头部 ==='
sudo head -10 $APP/FastPwds.txt 2>&1

echo
echo '=== sha256 of webshell candidates ==='
for f in $APP/command.php $APP/route.php $APP/tags.php $APP/config.php; do
    [ -f "$f" ] && sudo sha256sum "$f" 2>&1
done

echo
echo '=== TPshop login encrypt 函数 ==='
grep -rn 'encrypt\|md5\|password' $APP/admin/Logic/AdminLogic.php 2>/dev/null | head -10
find $APP/admin -name 'AdminLogic*' -o -name 'Login*' 2>/dev/null
echo
echo '-- common functions / encrypt --'
grep -rn 'function encrypt\|function check_pwd\|function admin_pwd' $APP/common.php $APP/admin/Common 2>/dev/null | head -10