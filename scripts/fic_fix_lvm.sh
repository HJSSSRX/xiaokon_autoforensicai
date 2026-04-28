#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== [1] 挂载检材3-2 ====="
mkdir -p /tmp/fic2026/srv2/ewf
SUDO ewfmount "/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材3-服务器/检材3-2.E01" /tmp/fic2026/srv2/ewf
SUDO ls -la /tmp/fic2026/srv2/ewf/
echo ""
echo "检材3-2 大小："
SUDO stat -c%s /tmp/fic2026/srv2/ewf/ewf1
echo ""
SUDO file /tmp/fic2026/srv2/ewf/ewf1
echo ""
SUDO mmls /tmp/fic2026/srv2/ewf/ewf1 2>&1 | head -10

echo ""
echo "===== [2] 把检材3-2 也加 loop ====="
SUDO losetup -fP --read-only /tmp/fic2026/srv2/ewf/ewf1
echo "当前 loop:"
SUDO losetup -a | grep fic2026

echo ""
echo "===== [3] 重扫 LVM ====="
SUDO pvscan 2>&1 | head -10
echo ""
SUDO vgscan 2>&1 | head -10
echo ""
SUDO vgchange -ay 2>&1 | head -10
echo ""
echo "===== [4] LV 列表 ====="
SUDO lvs 2>&1 | head -10
echo ""
SUDO lvdisplay 2>&1 | grep -E 'LV Path|LV Name|VG Name|LV Size'

echo ""
echo "===== [5] PC /etc/os-release ====="
PC_IMG="/tmp/fic2026/pc/ewf/ewf1"
echo "在 PC 镜像 root 分区（offset 19666944）查 /etc/os-release"
ETC_INODE=$(SUDO fls -o 19666944 "$PC_IMG" 2>/dev/null | awk '/^d.*\Wetc$/ {print $2}' | tr -d ':' | head -1)
echo "etc inode: $ETC_INODE"
if [ -n "$ETC_INODE" ]; then
  OSREL_INODE=$(SUDO fls -o 19666944 "$PC_IMG" "$ETC_INODE" 2>/dev/null | grep -E '\sos-release$' | awk '{print $2}' | tr -d ':' | head -1)
  echo "os-release inode: $OSREL_INODE"
  if [ -n "$OSREL_INODE" ]; then
    SUDO icat -o 19666944 "$PC_IMG" "$OSREL_INODE" 2>/dev/null
  fi
fi

echo ""
echo "===== [6] U盘 vc 文件大小 ====="
USB_IMG="/tmp/fic2026/usb/ewf/ewf1"
echo "U盘 fls 详细："
SUDO fls -l "$USB_IMG" 2>/dev/null | grep -iE 'vc|veracrypt|sample' | head -10
