#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
echo "=== clash-verge (前端 GUI) strings 含 9527 ==="
SUDO strings /tmp/pc_root/usr/bin/clash-verge | grep -B1 -A1 '9527' | head -20
echo ""
echo "=== clash-verge 所有 IP:Port ==="
SUDO strings /tmp/pc_root/usr/bin/clash-verge | grep -oE '(127\.0\.0\.1|localhost|0\.0\.0\.0):[0-9]+' | sort -u | head
echo ""
echo "=== verge-mihomo (kernel, 真正的 clash core) IP:Port ==="
SUDO strings /tmp/pc_root/usr/bin/verge-mihomo | grep -oE '(127\.0\.0\.1|localhost|0\.0\.0\.0):[0-9]{4,5}' | sort -u | head
SUDO strings /tmp/pc_root/usr/bin/verge-mihomo | grep -B1 -A1 '9527' | head -10
echo ""
echo "=== IPC bridge (Unix socket 模式的端口) ==="
SUDO strings /tmp/pc_root/usr/bin/clash-verge-service | grep -iE 'ipc_port|service_port|listen|9527|default_port|9097|33211' | head -20
