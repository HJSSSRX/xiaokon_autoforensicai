#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
SUDO strings /tmp/pc_root/usr/bin/clash-verge-service | grep -E '9527|127\.0\.0\.1:[0-9]+|0\.0\.0\.0:[0-9]+|localhost:[0-9]+' | head -20
echo "---"
SUDO strings /tmp/pc_root/usr/bin/clash-verge-service | grep -B1 -A1 '9527' | head -20
echo "---"
echo "=== service file ==="
SUDO cat /tmp/pc_root/etc/systemd/system/clash-verge-service.service
