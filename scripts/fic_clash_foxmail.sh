#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "==========================================" 
echo "C05: Clash Verge 代理端口"
echo "=========================================="
SUDO cat /tmp/pc_data/root/.local/share/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml 2>/dev/null

echo ""
echo "--- clash-verge-check.yaml ---"
SUDO cat /tmp/pc_data/root/.local/share/io.github.clash-verge-rev.clash-verge-rev/clash-verge-check.yaml 2>/dev/null

echo ""
echo "--- 该目录所有内容 ---"
SUDO ls -la /tmp/pc_data/root/.local/share/io.github.clash-verge-rev.clash-verge-rev/ 2>/dev/null

echo ""
echo "--- profile yaml 文件 ---"
SUDO find /tmp/pc_data/root/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/ -type f 2>/dev/null | head
echo ""
echo "--- profiles 内容 ---"
SUDO ls -la /tmp/pc_data/root/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/ 2>/dev/null
SUDO bash -c 'for f in /tmp/pc_data/root/.local/share/io.github.clash-verge-rev.clash-verge-rev/profiles/*.yaml; do
  echo "=== $f ==="
  cat "$f" 2>/dev/null | head -50
done'

echo ""
echo "==========================================" 
echo "C02: Foxmail 邮件"
echo "=========================================="
SUDO ls /tmp/pc_data/opt/apps/com.foxmail.deepin/ 2>/dev/null
SUDO ls -la /tmp/pc_data/root/.config/com.foxmail.deepin/ 2>/dev/null
SUDO ls -la /tmp/pc_data/root/.foxmail/ 2>/dev/null
echo ""
echo "--- Foxmail 数据位置 ---"
SUDO find /tmp/pc_data -maxdepth 6 -path '*foxmail*' -type d 2>/dev/null | head -10
echo ""
SUDO find /tmp/pc_data -name 'mail.box' -o -name '*.eml' -o -name 'Inbox*' -o -name '收件箱*' 2>/dev/null | head -20
echo ""
echo "--- 可能在 /root/.deepinwine 下（Wine 模式）---"
SUDO find /tmp/pc_data/root -name 'deepinwine*' -o -name '.wine' -o -name '*Foxmail*' 2>/dev/null | head -10

echo ""
echo "==========================================" 
echo "C06/C07: AI 软件（Cherry Studio / Chatbox）"
echo "=========================================="
echo "--- root .config 完整 ---"
SUDO ls /tmp/pc_data/root/.config/cef_user_data/ 2>/dev/null | head
SUDO cat /tmp/pc_data/root/.config/cef_user_data/Default/Preferences 2>/dev/null | head -100
echo ""
echo "--- Cherry Studio / ChatBox / AnythingLLM ---"
SUDO find /tmp/pc_data/root /tmp/pc_data/opt -maxdepth 6 -iname '*Cherry*' -o -iname 'ChatBox*' -o -iname '*Chatbot*' -o -iname '*Anything*' 2>/dev/null | head -10
echo ""
echo "--- 看 deepin app 全部 ---"
SUDO ls /tmp/pc_data/opt/apps/ 2>/dev/null
SUDO ls /tmp/pc_data/root/Applications/ 2>/dev/null
SUDO ls /tmp/pc_data/root/.local/share/applications/ 2>/dev/null

echo ""
echo "==========================================" 
echo "C04: APK 下载链接（推广设计图）"
echo "=========================================="
SUDO find /tmp/pc_data/root -maxdepth 6 -iname '*推广*' -o -iname '*ad*.png' -o -iname '*ad*.jpg' 2>/dev/null | head -5
SUDO find /tmp/pc_data/root/Pictures -maxdepth 4 -type f 2>/dev/null | head -20
SUDO find /tmp/pc_data/root/桌面 /tmp/pc_data/root/Desktop -type f 2>/dev/null | head -10
SUDO find /tmp/pc_data/root -maxdepth 4 -name '*.apk' -o -name '*推广*' -o -name '*tuiguang*' 2>/dev/null | head
