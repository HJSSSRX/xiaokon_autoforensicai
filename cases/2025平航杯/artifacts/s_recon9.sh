#!/bin/bash
S=/mnt/server
APP=$S/www/wwwroot/www.tpshop.com

echo '=== S01 系统首次安装/最早开机时间 ==='
sudo head -1 $S/var/log/anaconda/anaconda.log 2>&1
echo '-- /etc 目录创建时间 --'
sudo stat $S/etc/redhat-release 2>&1 | grep -E 'Modify|Birth'
echo '-- root home birthtime --'
sudo stat $S/root 2>&1 | grep -E 'Birth'
echo '-- wtmp 第一条 --'
sudo last -f $S/var/log/wtmp -F 2>&1 | grep -E 'reboot' | tail -1

echo
echo '=== S07 AUTH_CODE 配置值 ==='
sudo grep -rE "AUTH_CODE['\"]" $APP/application/config.php $APP/application/extra $APP/application/database.php 2>/dev/null | head -10
sudo cat $APP/application/config.php | grep -A1 -B1 'AUTH_CODE' 2>&1

echo
echo '=== S08 GD version ==='
sudo find $S/www/server/php -name 'php.ini' 2>/dev/null | head -3
ls $S/www/server/php/ 2>&1
sudo find $S/www/server/php -name 'gd*.so' 2>/dev/null | head -5
echo '-- search GD version str in php binaries --'
for php in $S/www/server/php/*/bin/php; do
    [ -x "$php" ] && {
        echo "## $php"
        sudo strings "$php" 2>/dev/null | grep -iE 'GD Version|gd 2\.|^GD ' | head -5
    }
done
echo
echo '-- search in gd.so --'
for so in $(sudo find $S/www/server/php -name 'gd*.so' 2>/dev/null); do
    echo "## $so"
    sudo strings "$so" | grep -iE '^bundled|^GD|libgd|^[0-9]+\.[0-9]+\.[0-9]+$' | head -5
done

echo
echo '=== S07 alt: tp_admin password from sql backup ==='
sudo grep -E 'tp_admin|INSERT INTO .tp_admin' $APP/backup/www_TPshop_com1.sql 2>/dev/null | head -10
echo '-- 找 admin 表中的 password 字段 --'
sudo grep -A 20 'CREATE TABLE .*tp_admin.* ' $APP/backup/www_TPshop_com1.sql 2>/dev/null | head -25