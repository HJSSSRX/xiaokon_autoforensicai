#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== PC _dde_data 完整 ====="
SUDO ls -la /tmp/pc_data/
echo ""
SUDO find /tmp/pc_data -maxdepth 3 -type d 2>/dev/null | head -50
echo ""
echo "--- _dde_data 里的 home/users ---"
SUDO ls /tmp/pc_data/home/ 2>/dev/null
SUDO ls /tmp/pc_data/_dde_data/ 2>/dev/null

echo ""
echo "===== PC root 分区 /home 重新看（之前看错了）====="
SUDO ls -la /tmp/pc_root/home/ 2>/dev/null
SUDO ls /tmp/pc_root/var/lib/ 2>/dev/null | head -20
SUDO ls /tmp/pc_root/persistent/ 2>/dev/null
SUDO ls /tmp/pc_root/data/ 2>/dev/null

echo ""
echo "===== PC 用户列表 ====="
SUDO awk -F: '($3>=1000)&&($1!="nobody")' /tmp/pc_root/etc/passwd | head -10
