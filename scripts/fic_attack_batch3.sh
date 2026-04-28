#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
MACCMS="$ROOT/var/www/html/maccms10"

echo "==========================================" 
echo "I03: ngrok.yml (域名)"
echo "=========================================="
SUDO cat $ROOT/root/.config/ngrok/ngrok.yml

echo ""
echo "==========================================" 
echo "/etc/hosts 看 mytidb IP（S11）"
echo "=========================================="
SUDO cat $ROOT/etc/hosts

echo ""
echo "==========================================" 
echo "Docker / LXC 网络配置"
echo "=========================================="
SUDO ip a 2>/dev/null
echo "(host 命令 - 静态)"
SUDO cat $ROOT/etc/lxc/default.conf 2>/dev/null
echo ""
SUDO cat $ROOT/var/lib/lxc/mytidb/config 2>/dev/null

echo ""
echo "==========================================" 
echo "S05/S06/S07: maccms 后台路径 + ICP + 主域名"
echo "=========================================="
echo "--- maccms 路由 route.php ---"
SUDO cat $MACCMS/route.php 2>/dev/null | head -40
echo ""
echo "--- application/route.php ---"
SUDO cat $MACCMS/application/route.php 2>/dev/null | head -50
echo ""
echo "--- application/extra/route.php ---"
SUDO cat $MACCMS/application/extra/route.php 2>/dev/null | head -50
echo ""
echo "--- runtime/data/admin_login_url（maccms 改名后的后台 URL 在数据库） ---"
SUDO find $MACCMS/runtime -name '*admin*' 2>/dev/null | head
echo ""
echo "--- maccms 安装目录 + .env / config ---"
SUDO find $MACCMS -maxdepth 3 -name '*.lock' -o -name '*.env' 2>/dev/null
echo ""
echo "--- 在 application/admin/ 找入口 ---"
SUDO ls $MACCMS/application/admin/
echo ""
SUDO cat $MACCMS/application/admin/common.php 2>/dev/null | head -30

echo ""
echo "==========================================" 
echo "S13: LXC mytidb 容器内部探索"
echo "=========================================="
SUDO ls -la $ROOT/var/lib/lxc/mytidb/
echo ""
echo "--- mytidb config（关键） ---"
SUDO cat $ROOT/var/lib/lxc/mytidb/config 2>/dev/null
echo ""
echo "--- mytidb rootfs ---"
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/ 2>/dev/null
echo ""
echo "--- mytidb /etc ---"
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/etc/ 2>/dev/null | head -30
echo ""
echo "--- mytidb 系统 ---"
SUDO cat $ROOT/var/lib/lxc/mytidb/rootfs/etc/os-release 2>/dev/null
echo ""
echo "--- mytidb 内 docker 服务/数据库二进制 ---"
SUDO find $ROOT/var/lib/lxc/mytidb/rootfs/usr -name 'tidb*' -o -name 'mysql*' -o -name 'mariadb*' -o -name 'tikv*' -o -name 'pd-server' 2>/dev/null | head -10
SUDO find $ROOT/var/lib/lxc/mytidb/rootfs/opt -type f 2>/dev/null | head -10
SUDO find $ROOT/var/lib/lxc/mytidb/rootfs/root -maxdepth 3 -type f 2>/dev/null | head -20
echo ""
echo "--- mytidb 容器内进程相关 / docker ---"
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/var/lib/docker 2>/dev/null
SUDO ls $ROOT/var/lib/lxc/mytidb/rootfs/var/lib/mysql 2>/dev/null

echo ""
echo "==========================================" 
echo "数据库实际运行（看 docker 容器 in /data/containers）"
echo "=========================================="
SUDO ls $ROOT/data/containers/ 2>/dev/null
SUDO find $ROOT/data/containers -name 'config.v2.json' -exec sudo bash -c 'jq -r .Name {}' \; 2>/dev/null | head
SUDO bash -c "for f in $ROOT/data/containers/*/config.v2.json; do
  jq -r '\"\\(.Name) | image=\\(.Image) | created=\\(.Created) | running=\\(.State.Running)\"' \"\$f\" 2>/dev/null
done" | head -10
