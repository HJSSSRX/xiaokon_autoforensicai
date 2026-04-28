#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

# 同时落盘答案
bash /mnt/e/项目/自动化取证/scripts/fic_save_b01_b02.sh

echo ""
echo "=========================================="
echo "服务器 RAID 组装"
echo "=========================================="

# 装 mdadm（如果没有）
command -v mdadm >/dev/null 2>&1 || { echo "装 mdadm..."; SUDO apt-get install -y mdadm 2>&1 | tail -3; }

echo ""
echo "--- mdadm --examine 看 RAID 元数据 ---"
SUDO mdadm --examine /dev/volum/root /dev/root/data 2>&1 | grep -E 'Magic|Version|Array UUID|Raid Level|Raid Devices|Active Devices|Working Devices|Layout|Chunk Size|Name|Role|State'

echo ""
echo "--- 组装 RAID ---"
# 双成员 RAID，可能是 RAID1
SUDO mdadm --assemble --readonly /dev/md0 /dev/volum/root /dev/root/data 2>&1
echo ""
SUDO cat /proc/mdstat 2>&1
echo ""
SUDO ls -la /dev/md* 2>&1

echo ""
echo "--- /dev/md0 文件系统识别 ---"
SUDO blkid /dev/md0 2>&1
SUDO file -s /dev/md0 2>&1 | head -3

echo ""
echo "=========================================="
echo "尝试挂载 RAID 卷"
echo "=========================================="
SUDO mkdir -p /tmp/srv_root
# 可能是 LVM on top of RAID（再嵌一层），或者直接 ext4/xfs
SUDO mount -o ro /dev/md0 /tmp/srv_root 2>&1
ls /tmp/srv_root | head -10
echo ""
SUDO cat /tmp/srv_root/etc/os-release 2>/dev/null | head -10
SUDO cat /tmp/srv_root/etc/fstab 2>/dev/null | head -10

echo ""
echo "=========================================="
echo "C01: 重新读 PC /etc/os-release（用 debugfs）"
echo "=========================================="
PC_IMG="/tmp/fic2026/pc/ewf/ewf1"
# 把 PC 镜像 root 分区也设 loop
SUDO losetup -fP --read-only "$PC_IMG" 2>/dev/null
PC_LOOP=$(SUDO losetup -j "$PC_IMG" | head -1 | cut -d: -f1)
echo "PC loop: $PC_LOOP"
SUDO partx -s "$PC_LOOP" 2>&1 | head -10

echo ""
echo "PC 各分区文件系统："
for p in ${PC_LOOP}p1 ${PC_LOOP}p2 ${PC_LOOP}p3 ${PC_LOOP}p4 ${PC_LOOP}p5; do
  [ -b "$p" ] || continue
  SIZE=$(SUDO blockdev --getsize64 "$p" 2>/dev/null)
  TYPE=$(SUDO blkid "$p" 2>/dev/null)
  echo "  $p ($(numfmt --to=iec --suffix=B ${SIZE:-0})): $TYPE"
done

echo ""
echo "--- 直接挂 PC root 分区 (offset 19666944 = ${PC_LOOP}p3 ?) ---"
SUDO mkdir -p /tmp/pc_root
# 找 ext4 分区
for p in ${PC_LOOP}p1 ${PC_LOOP}p2 ${PC_LOOP}p3 ${PC_LOOP}p4 ${PC_LOOP}p5; do
  [ -b "$p" ] || continue
  if SUDO blkid "$p" | grep -q ext4; then
    if [ ! -e /tmp/pc_root/etc ]; then
      SUDO mount -o ro "$p" /tmp/pc_root 2>&1 && [ -e /tmp/pc_root/etc/os-release ] && {
        echo "PC root 在 $p:"
        SUDO cat /tmp/pc_root/etc/os-release
        break
      } || SUDO umount /tmp/pc_root 2>/dev/null
    fi
  fi
done
