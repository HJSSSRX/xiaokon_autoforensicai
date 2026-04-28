#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
BIN=/tmp/pc_root/usr/bin/clash-verge-service

echo "=== IP:Port 字面串 ==="
SUDO strings $BIN | grep -oE '(127\.0\.0\.1|localhost|0\.0\.0\.0):[0-9]+' | sort -u
echo ""
echo "=== 只含 9527 但作为端口（前后不是字母数字 hash）==="
SUDO strings $BIN | grep -E '(^|[^0-9a-f])9527([^0-9a-f]|$)' | head -10
echo ""
echo "=== 所有 4-5 位端口（独立的） ==="
SUDO strings $BIN | grep -oE ':[0-9]{4,5}(/|$|")' | sort -u | head -20
echo ""
echo "=== 绑定字符串 ==="
SUDO strings $BIN | grep -iE 'bind|listen|port' | head -20

echo ""
echo "=== service-install 二进制 ==="
SUDO strings /tmp/pc_root/usr/bin/clash-verge-service-install | grep -oE '(127\.0\.0\.1|localhost|0\.0\.0\.0):[0-9]+' | sort -u

echo ""
echo "=== 查 Clash Verge GUI 前端二进制是否有端口 ==="
SUDO strings /tmp/pc_root/usr/bin/clash-verge | grep -oE '(127\.0\.0\.1|localhost|0\.0\.0\.0):[0-9]+' | sort -u | head

echo ""
echo "=== 查已运行进程的系统日志 (systemd + journal) ==="
SUDO find /tmp/pc_data/var/log /tmp/pc_root/var/log -name 'journal*' 2>/dev/null | head
SUDO grep -l 'clash-verge-service' /tmp/pc_data/var/log 2>/dev/null | head
echo ""
echo "=== 端口表（从实际运行过的 TCP 连接 /proc 或日志）==="
# journalctl 替代 - 读 var/log/syslog
SUDO grep -l '9527\|clash-verge-service' /tmp/pc_root/var/log/* /tmp/pc_data/var/log/* 2>/dev/null
