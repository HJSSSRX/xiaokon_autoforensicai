#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"

echo "==========================================" 
echo "LXC mytidb 容器探查"
echo "=========================================="
SUDO ls -la $ROOT/var/lib/lxc/mytidb/
echo ""
echo "--- config 文件 ---"
SUDO cat $ROOT/var/lib/lxc/mytidb/config 2>/dev/null

echo ""
echo "--- rootfs ---"
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/ 2>/dev/null | head
echo ""
echo "--- LXC 容器内 hostname ---"
SUDO cat $ROOT/var/lib/lxc/mytidb/rootfs/etc/hostname 2>/dev/null
echo ""
echo "--- LXC 容器内 os-release ---"
SUDO cat $ROOT/var/lib/lxc/mytidb/rootfs/etc/os-release 2>/dev/null

echo ""
echo "==========================================" 
echo "网站根目录探测（更全面）"
echo "=========================================="
echo "--- /etc/nginx 完整 ---"
SUDO ls -la $ROOT/etc/nginx/
echo ""
echo "--- nginx.conf 完整 ---"
SUDO cat $ROOT/etc/nginx/nginx.conf 2>/dev/null
echo ""
echo "--- sites-available ---"
SUDO ls $ROOT/etc/nginx/sites-available/ 2>/dev/null
SUDO ls -la $ROOT/etc/nginx/sites-enabled/ 2>/dev/null
SUDO bash -c "for f in $ROOT/etc/nginx/sites-available/*; do echo '=== '\$f' ==='; sudo cat \$f 2>/dev/null; done"
echo ""
echo "--- /var/www 内容 ---"
SUDO ls -la $ROOT/var/www/
SUDO ls $ROOT/var/www/html/ 2>/dev/null | head -20
echo ""
echo "--- /srv 内容 ---"
SUDO ls -la $ROOT/srv/ 2>/dev/null
echo ""
echo "--- /data 内容（根下） ---"
SUDO ls -la $ROOT/data/ 2>/dev/null
echo ""
echo "--- /db 内容（根下） ---"
SUDO ls -la $ROOT/db/ 2>/dev/null
echo ""
echo "--- /home/mac 内容 ---"
SUDO ls -la $ROOT/home/mac/ 2>/dev/null
echo ""
echo "--- /opt 内容 ---"
SUDO ls $ROOT/opt/ 2>/dev/null

echo ""
echo "==========================================" 
echo "关键配置/历史"
echo "=========================================="
echo "--- mac 用户 bash_history ---"
SUDO cat $ROOT/home/mac/.bash_history 2>/dev/null | tail -50
echo ""
echo "--- root bash_history ---"
SUDO cat $ROOT/root/.bash_history 2>/dev/null | tail -50

echo ""
echo "==========================================" 
echo "S03 docker 镜像（重新查所有位置）"
echo "=========================================="
SUDO find $ROOT/var/lib/docker -maxdepth 4 -type f -name '*.json' 2>/dev/null | head -20
echo ""
echo "--- buildkit ---"
SUDO ls $ROOT/var/lib/docker/buildkit/ 2>/dev/null
echo ""
echo "--- containers ---"
SUDO ls $ROOT/var/lib/docker/containers/ 2>/dev/null
echo ""
echo "--- overlay2 ---"
SUDO ls $ROOT/var/lib/docker/overlay2/ 2>/dev/null | head
echo ""
echo "--- LXD images（也叫'docker镜像'？） ---"
SUDO ls $ROOT/var/lib/lxd/images/ 2>/dev/null
SUDO find $ROOT/var/lib/lxd/images -maxdepth 2 2>/dev/null | head -10
