#!/usr/bin/env bash
# 探检材形态（合规：看系统类型/分区结构，不读业务数据）
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== [1] LVM 工具检查 ====="
command -v vgscan && command -v lvscan && command -v lvdisplay && echo "[OK] lvm2" || echo "[--] lvm2 missing, 装: sudo apt install lvm2"

echo ""
echo "===== [2] 检材1-Linux 桌面 发行版 ====="
PC_IMG="/tmp/fic2026/pc/ewf/ewf1"
# 分区2 (offset=2048) 是 boot；分区3 (offset=3147776) 是 root
echo "尝试看 /etc/os-release（合规：看发行版本身）"
SUDO icat -o 19666944 "$PC_IMG" 0 2>/dev/null | head -1 >/dev/null  # warmup
# 用 fls 找 /etc/os-release inode
echo "在 root 分区（offset 19666944）找 /etc/os-release..."
INODE=$(SUDO fls -o 19666944 -p -r "$PC_IMG" 2>/dev/null | grep -E '/etc/os-release$' | head -1 | awk '{print $2}' | tr -d ':')
echo "inode = $INODE"
if [ -n "$INODE" ]; then
  SUDO icat -o 19666944 "$PC_IMG" "$INODE" 2>/dev/null | head -20
fi

echo ""
echo "===== [3] 检材3-LVM 探测 ====="
SRV_IMG="/tmp/fic2026/srv/ewf/ewf1"
SUDO losetup -fP --read-only "$SRV_IMG" 2>&1
LOOP=$(SUDO losetup -j "$SRV_IMG" | head -1 | cut -d: -f1)
echo "Loop = $LOOP"
SUDO partx -s "$LOOP" 2>&1 | head -10
echo ""
echo "PV 扫描："
SUDO pvscan 2>&1 | head -5
echo ""
echo "VG 扫描："
SUDO vgscan 2>&1 | head -5

echo ""
echo "===== [4] 检材4-U盘 NTFS 根目录（合规：看文件清单）====="
USB_IMG="/tmp/fic2026/usb/ewf/ewf1"
echo "fls 根目录前 20 项："
SUDO fls "$USB_IMG" 2>/dev/null | head -20
