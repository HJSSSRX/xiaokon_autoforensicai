#!/usr/bin/env bash
# FIC2026 P1 工具：jadx, mongosh, zeek（不在 apt 标准仓库）
# 注：用户机已添加 zeek 的 OBS 仓库（健康检查可见）

PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== [1] jadx (Java 反编译) ====="
if command -v jadx >/dev/null; then
  echo "OK: jadx already installed"
else
  cd /tmp
  # 用 GitHub release 直接下载（约 30 MB）
  wget -q "https://github.com/skylot/jadx/releases/download/v1.5.0/jadx-1.5.0.zip" -O jadx.zip && \
  SUDO mkdir -p /opt/jadx && \
  SUDO unzip -q -o jadx.zip -d /opt/jadx && \
  SUDO ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx && \
  SUDO ln -sf /opt/jadx/bin/jadx-gui /usr/local/bin/jadx-gui && \
  echo "OK: jadx installed" || echo "FAIL: jadx"
fi

echo ""
echo "===== [2] mongosh (MongoDB 客户端) ====="
if command -v mongosh >/dev/null; then
  echo "OK: mongosh already installed"
else
  cd /tmp
  wget -q "https://downloads.mongodb.com/compass/mongodb-mongosh_2.3.0_amd64.deb" -O mongosh.deb && \
  SUDO dpkg -i mongosh.deb 2>&1 | tail -5 && \
  echo "OK: mongosh installed" || echo "FAIL: mongosh"
fi

echo ""
echo "===== [3] zeek (网络流量分析) ====="
if command -v zeek >/dev/null; then
  echo "OK: zeek already installed"
else
  SUDO apt-get install -y zeek 2>&1 | tail -3
  # zeek 装在 /opt/zeek/bin/zeek，加 PATH
  if [ -f /opt/zeek/bin/zeek ]; then
    SUDO ln -sf /opt/zeek/bin/zeek /usr/local/bin/zeek
    echo "OK: zeek linked"
  fi
fi

echo ""
echo "===== verify ====="
for t in jadx mongosh zeek; do
  command -v "$t" >/dev/null && echo "OK : $t  ($(which $t))" || echo "-- : $t"
done
