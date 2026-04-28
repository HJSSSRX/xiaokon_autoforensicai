#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
echo "=== /tmp/pc_root/opt ==="
SUDO ls $PCR/opt/ /tmp/pc_root/opt/ 2>/dev/null
echo ""
echo "=== 找 clash-verge-service 二进制 ==="
SUDO find /tmp/pc_root -maxdepth 5 -iname '*clash*' 2>/dev/null | head -20
SUDO find /tmp/pc_root -maxdepth 5 -iname '*verge*' 2>/dev/null | head -20
echo ""
echo "=== grep 9527 全盘 pc_root (排除 cache) ==="
SUDO grep -rln '9527' /tmp/pc_root/etc /tmp/pc_root/usr /tmp/pc_root/lib /tmp/pc_root/opt 2>/dev/null | head -20
echo ""
echo "=== grep 9527 pc_data 排除大目录 ==="
SUDO grep -rln '9527' /tmp/pc_data/root/.config /tmp/pc_data/root/.local 2>/dev/null | head -10
echo ""
echo "=== systemd services 含 clash / verge ==="
SUDO ls /tmp/pc_root/etc/systemd/system/ 2>/dev/null | grep -i 'clash\|verge'
SUDO cat /tmp/pc_root/etc/systemd/system/clash-verge-service.service 2>/dev/null
echo ""
echo "=== .deb 安装的 clash-verge (dpkg) ==="
SUDO dpkg-deb -c /tmp/pc_data/root/*.deb 2>/dev/null | head
SUDO find /tmp/pc_data/root -name 'Clash.Verge*.deb' 2>/dev/null
echo ""
echo "=== clash-verge 主二进制字符串找 9527 ==="
SUDO strings /tmp/pc_root/usr/bin/clash-verge 2>/dev/null | grep -E '9527|127.0.0.1:[0-9]|localhost:[0-9]' | head -10
SUDO strings /tmp/pc_root/usr/lib/clash-verge/clash-verge 2>/dev/null | grep '9527' | head
echo ""
echo "=== 查 clash-verge service binary ==="
SUDO find /tmp/pc_root -name 'clash-verge-service' -o -name 'clash-verge' -o -name 'verge-mihomo' 2>/dev/null | head
