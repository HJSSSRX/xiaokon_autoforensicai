#!/usr/bin/env bash
# 装 jadx：从 GitHub API 拿最新版下载
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

# 拿最新版 URL
LATEST=$(curl -s https://api.github.com/repos/skylot/jadx/releases/latest | grep -oP '"browser_download_url": "\K[^"]+jadx-[0-9.]+\.zip' | head -1)
echo "Latest jadx URL: $LATEST"

if [ -z "$LATEST" ]; then
  echo "FAIL: 无法获取最新版 URL，尝试已知稳定版 1.4.7"
  LATEST="https://github.com/skylot/jadx/releases/download/v1.4.7/jadx-1.4.7.zip"
fi

cd /tmp
wget -q "$LATEST" -O jadx.zip
ls -la jadx.zip

if [ -s jadx.zip ]; then
  SUDO mkdir -p /opt/jadx
  SUDO unzip -q -o jadx.zip -d /opt/jadx
  SUDO ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx
  SUDO ln -sf /opt/jadx/bin/jadx-gui /usr/local/bin/jadx-gui
  command -v jadx && jadx --version && echo "OK: jadx" || echo "FAIL"
else
  echo "FAIL: 下载失败"
fi
