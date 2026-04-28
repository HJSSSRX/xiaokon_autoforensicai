#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== btrfs 子卷探测 ====="
SUDO ls -la /tmp/srv_root/ 2>&1
echo ""
echo "---@rootfs 内容---"
SUDO ls /tmp/srv_root/@rootfs/ 2>&1 | head -25

ROOT="/tmp/srv_root/@rootfs"

echo ""
echo "==========================================" 
echo "S01: 服务器 OS 版本"
echo "=========================================="
SUDO cat $ROOT/etc/os-release 2>/dev/null

echo ""
echo "==========================================" 
echo "S02: 根分区 UUID"
echo "=========================================="
SUDO cat $ROOT/etc/fstab 2>/dev/null | grep -v '^#' | grep -v '^\s*$'

echo ""
echo "==========================================" 
echo "服务器 hostname/users"
echo "=========================================="
SUDO cat $ROOT/etc/hostname 2>/dev/null
echo "---"
SUDO awk -F: '($3>=1000)&&($1!="nobody"){print}' $ROOT/etc/passwd 2>/dev/null | head -10

echo ""
echo "==========================================" 
echo "S03: docker 镜像（最新创建时间）"
echo "=========================================="
echo "--- 看 Docker 是否存在 ---"
SUDO ls $ROOT/var/lib/docker/ 2>/dev/null | head
echo ""
echo "--- Docker images metadata ---"
SUDO ls $ROOT/var/lib/docker/image/ 2>/dev/null
SUDO find $ROOT/var/lib/docker/image -name 'repositories.json' 2>/dev/null | head -3
SUDO find $ROOT/var/lib/docker/image -name 'repositories.json' -exec cat {} \; 2>/dev/null

echo ""
echo "==========================================" 
echo "S04: 根分区快照（btrfs snapshot）"
echo "=========================================="
SUDO ls -la /tmp/srv_root/ 2>&1

echo ""
echo "==========================================" 
echo "S12/S17: 数据库服务/容器"
echo "=========================================="
echo "--- /var/lib 主要目录 ---"
SUDO ls $ROOT/var/lib/ 2>/dev/null
echo ""
echo "--- systemd 服务 (mysql/mongo/redis/postgres) ---"
SUDO ls $ROOT/etc/systemd/system/multi-user.target.wants/ 2>/dev/null | head -30
SUDO ls $ROOT/lib/systemd/system/ 2>/dev/null | grep -iE 'mysql|mongo|redis|postgres|maria' | head

echo ""
echo "==========================================" 
echo "宝塔面板?"
echo "=========================================="
SUDO ls $ROOT/www/ 2>/dev/null | head
SUDO ls $ROOT/www/server/ 2>/dev/null | head -20
SUDO ls $ROOT/www/server/panel/ 2>/dev/null | head

echo ""
echo "==========================================" 
echo "网站目录"
echo "=========================================="
SUDO ls $ROOT/www/wwwroot/ 2>/dev/null | head -20
