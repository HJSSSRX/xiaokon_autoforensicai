#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"

echo "==========================================" 
echo "btrfs 完整子卷列表（S04 根分区快照）"
echo "=========================================="
SUDO btrfs subvolume list /tmp/srv_root 2>&1 || echo "btrfs cmd 不可用，尝试别的"
echo ""
echo "--- 看 /tmp/srv_root 所有可见目录（btrfs 顶层） ---"
SUDO ls -la /tmp/srv_root/

echo ""
echo "==========================================" 
echo "S03: Docker 镜像最新创建时间"
echo "=========================================="
echo "--- imagedb 看实际镜像 metadata ---"
SUDO ls $ROOT/var/lib/docker/image/overlay2/imagedb/content/sha256/ 2>/dev/null | head
echo ""
echo "--- 数量 ---"
SUDO ls $ROOT/var/lib/docker/image/overlay2/imagedb/content/sha256/ 2>/dev/null | wc -l
echo ""
echo "--- 各镜像 metadata 的 created 时间 ---"
SUDO bash -c "for f in $ROOT/var/lib/docker/image/overlay2/imagedb/content/sha256/*; do
  jq -r '\"\\(.created) \\(.config.Env)\"' \"\$f\" 2>/dev/null | head -1
done" | sort -r | head -10

echo ""
echo "==========================================" 
echo "S12 / S17: LXC / LXD 容器"
echo "=========================================="
echo "--- /var/lib/lxd ---"
SUDO ls $ROOT/var/lib/lxd/ 2>/dev/null
echo ""
echo "--- LXD containers ---"
SUDO ls $ROOT/var/lib/lxd/containers/ 2>/dev/null
echo ""
echo "--- LXD storage pools ---"
SUDO ls $ROOT/var/lib/lxd/storage-pools/ 2>/dev/null
SUDO find $ROOT/var/lib/lxd/storage-pools/ -maxdepth 4 -type d 2>/dev/null | head -30
echo ""
echo "--- LXD database ---"
SUDO ls $ROOT/var/lib/lxd/database/ 2>/dev/null

echo ""
echo "--- /var/lib/lxc ---"
SUDO ls $ROOT/var/lib/lxc/ 2>/dev/null

echo ""
echo "--- /var/snap/lxd ---"
SUDO ls $ROOT/var/snap/lxd/ 2>/dev/null
SUDO ls $ROOT/var/snap/lxd/common/lxd/containers/ 2>/dev/null
SUDO ls $ROOT/var/snap/lxd/common/lxd/storage-pools/ 2>/dev/null

echo ""
echo "==========================================" 
echo "网站根目录探测"
echo "=========================================="
echo "--- nginx 配置 ---"
SUDO ls $ROOT/etc/nginx/sites-enabled/ 2>/dev/null
SUDO ls $ROOT/etc/nginx/conf.d/ 2>/dev/null
SUDO cat $ROOT/etc/nginx/nginx.conf 2>/dev/null | grep -E 'root|server_name|listen' | head -20
echo ""
echo "--- 各 sites-enabled ---"
SUDO bash -c "for f in $ROOT/etc/nginx/sites-enabled/*; do echo \"=== \$f ===\"; cat \"\$f\"; done" 2>/dev/null
echo ""
echo "--- conf.d 各文件 ---"
SUDO bash -c "for f in $ROOT/etc/nginx/conf.d/*.conf; do echo \"=== \$f ===\"; cat \"\$f\"; done" 2>/dev/null

echo ""
echo "==========================================" 
echo "网站文件位置（可能的）"
echo "=========================================="
SUDO ls $ROOT/var/www/ 2>/dev/null
SUDO ls $ROOT/srv/ 2>/dev/null
SUDO ls $ROOT/data/ 2>/dev/null
SUDO ls $ROOT/db/ 2>/dev/null
SUDO ls $ROOT/home/mac/ 2>/dev/null

echo ""
echo "==========================================" 
echo "PostgreSQL"
echo "=========================================="
SUDO ls $ROOT/var/lib/postgresql/ 2>/dev/null
SUDO ls $ROOT/etc/postgresql/ 2>/dev/null
