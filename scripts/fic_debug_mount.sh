#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== 清理旧挂载 ====="
SUDO umount -l /tmp/fic2026/pc/ewf 2>/dev/null
SUDO umount -l /tmp/fic2026/srv/ewf 2>/dev/null
SUDO umount -l /tmp/fic2026/usb/ewf 2>/dev/null
SUDO rm -rf /tmp/fic2026
mkdir -p /tmp/fic2026/pc/ewf
mkdir -p /tmp/fic2026/srv/ewf
mkdir -p /tmp/fic2026/usb/ewf

echo ""
echo "===== [1] PC E01 挂载调试 ====="
SUDO ewfmount "/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材1-计算机.E01" /tmp/fic2026/pc/ewf
echo "Exit: $?"
ls -la /tmp/fic2026/pc/ewf/

echo ""
echo "===== [2] 服务器 E01 挂载调试 ====="
SUDO ewfmount "/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材3-服务器/检材3-1.E01" /tmp/fic2026/srv/ewf
echo "Exit: $?"
ls -la /tmp/fic2026/srv/ewf/

echo ""
echo "===== [3] U盘 E01 挂载调试 ====="
SUDO ewfmount "/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材4-U盘.E01" /tmp/fic2026/usb/ewf
echo "Exit: $?"
ls -la /tmp/fic2026/usb/ewf/

echo ""
echo "===== [4] 分区分析 ====="
for img in /tmp/fic2026/pc/ewf/ewf1 /tmp/fic2026/srv/ewf/ewf1 /tmp/fic2026/usb/ewf/ewf1; do
  if [ -f "$img" ]; then
    echo ""
    echo "--- $img ---"
    file "$img" 2>/dev/null | head -1
    SUDO mmls "$img" 2>&1 | head -15
  fi
done
