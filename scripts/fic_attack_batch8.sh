#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
HIST="$ROOT/root/history"

echo "==========================================" 
echo "I03: ngrok 完整域名"
echo "=========================================="
SUDO grep -o 'ngrok[^"]*' $ROOT/var/log/nginx/access.log.1 2>/dev/null | sort -u | head -10
echo ""
echo "--- 看 access.log.1 中包含 ngrok 的完整行 ---"
SUDO grep 'ngrok' $ROOT/var/log/nginx/access.log.1 2>/dev/null | head -5

echo ""
echo "==========================================" 
echo "S13: TiDB 版本（看 .tiup）"
echo "=========================================="
SUDO ls $ROOT/root/.tiup/ 2>/dev/null
SUDO ls $HIST/root/.tiup/ 2>/dev/null
echo ""
SUDO ls $ROOT/root/.tiup/components/ 2>/dev/null
SUDO ls $HIST/root/.tiup/components/ 2>/dev/null
echo ""
SUDO ls $ROOT/root/.tiup/components/tidb/ 2>/dev/null
SUDO ls $HIST/root/.tiup/components/tidb/ 2>/dev/null
echo ""
echo "--- TiUP playground 配置 ---"
SUDO find $ROOT/root/.tiup -maxdepth 5 -name '*.yaml' -o -name '*.yml' 2>/dev/null | head
SUDO find $HIST/root/.tiup -maxdepth 5 -name '*.yaml' -o -name '*.yml' 2>/dev/null | head
echo ""
echo "--- TiUP Manifest 看 TiDB 版本 ---"
SUDO ls $HIST/root/.tiup/manifests/ 2>/dev/null
SUDO cat $HIST/root/.tiup/manifests/tidb.json 2>/dev/null | head -30
echo ""
echo "--- ZFS 数据集 ---"
SUDO find $ROOT/db /db 2>/dev/null
SUDO find $HIST/db -maxdepth 4 2>/dev/null | head -20
SUDO ls $HIST/db/tidb 2>/dev/null
# zfs pool 数据可能在快照内
SUDO find $ROOT/var/lib/lxc /var/lib/zfs 2>/dev/null

echo ""
echo "==========================================" 
echo "S16: 未用的文件系统（zfs 已用，看 fstab + mount + zpool）"
echo "=========================================="
echo "--- 已用 fs ---"
echo "btrfs (根)"
echo "swap"
echo "vfat (EFI boot)"
echo "udf,iso9660 (光驱配置)"
echo "ext4 (?)"
echo ""
echo "--- ext4 在该机器是否实际使用 ---"
SUDO grep ext4 $ROOT/etc/fstab 2>/dev/null
SUDO blkid /dev/loop4p1 2>/dev/null
SUDO mount | grep ext4
echo ""
echo "--- ZFS 已使用证明 ---"
SUDO grep zfs $ROOT/etc/fstab 2>/dev/null
echo "(zfs.target service active)"
echo ""
echo "--- xfs 工具 ---"
SUDO ls $ROOT/sbin/mkfs.xfs 2>/dev/null
SUDO ls $ROOT/usr/sbin/mkfs.xfs 2>/dev/null
SUDO grep -i xfs $ROOT/etc/fstab 2>/dev/null

echo ""
echo "==========================================" 
echo "S08: maccms 分类（看 install.sql）"
echo "=========================================="
MACCMS="$ROOT/var/www/html/maccms10"
SUDO ls $MACCMS/application/data/install/ 2>/dev/null | head
SUDO ls $MACCMS/application/install/ 2>/dev/null | head
echo ""
echo "--- install.sql 找 mac_type ---"
SUDO grep -A2 -i 'INSERT INTO.*mac_type\|分类3' $MACCMS/install.sql 2>/dev/null | head -30
SUDO find $MACCMS -name 'install.sql' 2>/dev/null
SUDO find $MACCMS -name '*.sql' 2>/dev/null | head
echo ""
echo "--- /root/history 里的 mac2 数据库 ---"
SUDO find $HIST -path '*mysql/mac2*' -type f 2>/dev/null | head
SUDO find $HIST -path '*mac2*' -type f 2>/dev/null | head
SUDO find $HIST -name 'mac_type*' 2>/dev/null | head -5

echo ""
echo "==========================================" 
echo "找 mysql/maccms 实际数据 - LXC 容器内"
echo "=========================================="
echo "--- /var/lib/lxc/mytidb 完整 ---"
SUDO find $HIST/var/lib/lxc 2>/dev/null
SUDO ls $HIST/var/lib/lxc/mytidb/ 2>/dev/null
echo ""
echo "--- LXC mytidb rootfs 在哪？config 写 dir:/db/tidb ---"
echo "(/db/tidb 在 ZFS 数据集中，需要 zpool import 看)"
SUDO ls -la $ROOT/db 2>/dev/null
SUDO mount | grep ' /db' 2>/dev/null
SUDO zpool list 2>/dev/null
SUDO zpool import 2>/dev/null
