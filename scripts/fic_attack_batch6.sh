#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
ROOT="/tmp/srv_root/@rootfs"
HIST="$ROOT/root/history"

echo "==========================================" 
echo "btrfs 快照里完整 mac2 数据库 (mac_config 表)"
echo "=========================================="
echo "--- /root/history/db/tidb 看 LXC 容器历史数据 ---"
SUDO ls $HIST/db/tidb/ 2>/dev/null | head
echo ""
SUDO ls $HIST/db/tidb/var/lib/mysql/ 2>/dev/null | head -20
echo ""
SUDO ls $HIST/db/tidb/var/lib/mysql/mac2/ 2>/dev/null | head -50
echo ""
echo "--- 数据库版本 (S13) ---"
SUDO cat $HIST/db/tidb/etc/os-release 2>/dev/null
SUDO ls $HIST/db/tidb/usr/sbin/mysqld $HIST/db/tidb/usr/sbin/mariadbd $HIST/db/tidb/usr/sbin/tidb-server 2>/dev/null
echo ""
echo "--- mac_config 字符串提取 ---"
SUDO strings $HIST/db/tidb/var/lib/mysql/mac2/mac_config.ibd 2>/dev/null | head -300

echo ""
echo "==========================================" 
echo "I03: ngrok agent log（找实际访问域名）"
echo "=========================================="
SUDO find $ROOT -path '*/ngrok/*log*' -o -path '*ngrok*tunnel*' 2>/dev/null | head -5
SUDO find $ROOT -name 'ngrok.log' -o -name 'agent.log' 2>/dev/null | head -10
SUDO find $HIST -name '*ngrok*' 2>/dev/null | head -5
echo ""
echo "--- ngrok 默认运行时数据 ---"
SUDO ls $ROOT/root/.ngrok2/ 2>/dev/null
SUDO ls $ROOT/root/.config/ngrok/ 2>/dev/null
SUDO cat $ROOT/root/.config/ngrok/agent.log 2>/dev/null | tail
echo ""
# 看 nginx access log 是否有 ngrok 相关 referer/host
SUDO grep -i 'ngrok' $ROOT/var/log/nginx/access.log 2>/dev/null | head -5
SUDO grep -i 'ngrok' $ROOT/var/log/nginx/error.log 2>/dev/null | head -5
echo ""
echo "--- nginx 所有 access log 中 Host 头不一样的请求 ---"
SUDO awk '{print $4, $6, $7}' $ROOT/var/log/nginx/access.log 2>/dev/null | head -5

echo ""
echo "==========================================" 
echo "B03: SampleVC.exe 详细字符串"
echo "=========================================="
EXE="/tmp/fic_extract/SampleVC.exe"
echo "--- 全部字符串 (n=8) ---"
strings -a -n 8 $EXE 2>/dev/null | head -100

echo ""
echo "==========================================" 
echo "C02: 邮件 - 浏览器 / Foxmail / Thunderbird"
echo "=========================================="
SUDO find /tmp/pc_data/root -maxdepth 5 -type d \( -name '.thunderbird' -o -name '.mozilla-thunderbird' -o -name 'Foxmail*' -o -iname '*mail*' \) 2>/dev/null | head -10
echo ""
echo "--- root 用户 .mozilla/firefox profile ---"
SUDO ls /tmp/pc_data/root/.mozilla/firefox/ 2>/dev/null

echo ""
echo "==========================================" 
echo "C06/C07: AI 软件"
echo "=========================================="
SUDO find /tmp/pc_data /tmp/pc_root -maxdepth 5 \( -iname 'ollama' -o -iname '*Cherry*' -o -iname 'ChatBox*' -o -iname '*LM*Studio*' -o -iname '*Anything*' -o -iname '.ollama' \) 2>/dev/null | head -10
echo ""
SUDO ls /tmp/pc_data/root/.config/ | head -50
echo ""
SUDO ls /tmp/pc_data/opt/apps/ 2>/dev/null | head -20

echo ""
echo "==========================================" 
echo "C05: VPN 软件"
echo "=========================================="
SUDO find /tmp/pc_data /tmp/pc_root -maxdepth 5 \( -iname '*v2ray*' -o -iname '*clash*' -o -iname '*Qv2ray*' -o -iname '*ssr*' -o -iname '*sniffy*' -o -iname '*shadowsocks*' \) 2>/dev/null | head -20
SUDO find /tmp/pc_data/opt -type d 2>/dev/null | head -30
