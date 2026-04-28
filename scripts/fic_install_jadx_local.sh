#!/usr/bin/env bash
# 从用户已下载的本地 zip 装 jadx
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

ZIP="/mnt/e/download/AIneed/jadx-1.5.5.zip"
[ -f "$ZIP" ] || { echo "FAIL: $ZIP not found"; exit 1; }

SUDO mkdir -p /opt/jadx
SUDO unzip -q -o "$ZIP" -d /opt/jadx
SUDO ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx
SUDO ln -sf /opt/jadx/bin/jadx-gui /usr/local/bin/jadx-gui
SUDO chmod +x /opt/jadx/bin/jadx /opt/jadx/bin/jadx-gui

command -v jadx && jadx --version 2>&1 | head -2 && echo "OK: jadx" || echo "FAIL"
