#!/usr/bin/env bash
# Purpose : Install forensics tools into WSL Ubuntu.
# Usage   : bash 01_install_wsl_tools.sh
# Tested  : Ubuntu 22.04 / 24.04 on WSL2
set -euo pipefail

echo "=========================================="
echo "  forensics-agent-starter WSL 工具安装"
echo "=========================================="
echo ""

# ---------------------------------------------------------------
# 0. Pre-flight checks
# ---------------------------------------------------------------
echo "[0/5] 环境检查"
if ! command -v apt-get &>/dev/null; then
    echo "ERROR: apt-get not found. This script requires Ubuntu/Debian."
    exit 1
fi
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  Disk free: $(df -h / | tail -1 | awk '{print $4}')"
echo ""

# ---------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------
echo "[1/5] apt 系统包"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    sqlite3 \
    python3 python3-pip python3-venv python3-dev \
    ripgrep jq file unzip p7zip-full xxd \
    libimage-exiftool-perl \
    libsqlcipher-dev \
    openssl libssl-dev \
    btrfs-progs lvm2 \
    sleuthkit ewf-tools afflib-tools \
    libbde-utils libfsapfs-utils \
    tshark \
    binwalk \
    curl wget git

echo "  [OK] 系统包安装完成"

# ---------------------------------------------------------------
# 2. radare2 (from GitHub release if not present)
# ---------------------------------------------------------------
echo ""
echo "[2/5] radare2"
if command -v r2 &>/dev/null; then
    echo "  [OK] r2 已安装: $(r2 -v 2>&1 | head -1)"
else
    echo "  安装 radare2..."
    R2_VER="5.9.8"
    R2_DEB="radare2_${R2_VER}_amd64.deb"
    R2_URL="https://github.com/radareorg/radare2/releases/download/${R2_VER}/${R2_DEB}"
    if curl -fsSL -o "/tmp/${R2_DEB}" "$R2_URL" 2>/dev/null; then
        sudo dpkg -i "/tmp/${R2_DEB}" || sudo apt-get install -f -y
        rm -f "/tmp/${R2_DEB}"
        echo "  [OK] r2 ${R2_VER} installed"
    else
        echo "  [WARN] 无法下载 r2 deb，尝试 apt..."
        sudo apt-get install -y radare2 2>/dev/null || echo "  [SKIP] radare2 安装失败，请手动安装"
    fi
fi

# ---------------------------------------------------------------
# 3. jadx (from GitHub release if not present)
# ---------------------------------------------------------------
echo ""
echo "[3/5] jadx"
if command -v jadx &>/dev/null; then
    echo "  [OK] jadx 已安装: $(jadx --version 2>&1 | head -1)"
else
    echo "  安装 jadx..."
    JADX_VER="1.5.1"
    JADX_ZIP="jadx-${JADX_VER}.zip"
    JADX_URL="https://github.com/skylot/jadx/releases/download/v${JADX_VER}/${JADX_ZIP}"
    JADX_DIR="/opt/jadx"
    if curl -fsSL -o "/tmp/${JADX_ZIP}" "$JADX_URL" 2>/dev/null; then
        sudo mkdir -p "$JADX_DIR"
        sudo unzip -oq "/tmp/${JADX_ZIP}" -d "$JADX_DIR"
        sudo chmod +x "$JADX_DIR/bin/jadx" "$JADX_DIR/bin/jadx-gui"
        sudo ln -sf "$JADX_DIR/bin/jadx" /usr/local/bin/jadx
        rm -f "/tmp/${JADX_ZIP}"
        echo "  [OK] jadx ${JADX_VER} installed to ${JADX_DIR}"
    else
        echo "  [WARN] 无法下载 jadx，请手动安装"
    fi
    # jadx requires JDK
    if ! command -v java &>/dev/null; then
        echo "  安装 JDK (jadx 依赖)..."
        sudo apt-get install -y --no-install-recommends default-jdk-headless
    fi
fi

# ---------------------------------------------------------------
# 4. Python venv + forensic packages
# ---------------------------------------------------------------
echo ""
echo "[4/5] Python venv"
VENV_DIR="${VENV_DIR:-$HOME/.venv-forensics}"
if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
pip install --upgrade pip wheel -q

echo "  安装 Python 取证包..."
pip install -q \
    pycryptodome \
    sqlcipher3-binary \
    openpyxl \
    pandas \
    python-evtx \
    volatility3 \
    requests

echo "  [OK] venv @ $VENV_DIR"

# ---------------------------------------------------------------
# 5. Verification
# ---------------------------------------------------------------
echo ""
echo "[5/5] 验证"
check() {
    if command -v "$1" &>/dev/null; then
        printf "  [OK]   %-16s %s\n" "$1" "$(command -v "$1")"
    else
        printf "  [MISS] %-16s\n" "$1"
    fi
}

check sqlite3
check strings
check grep
check find
check file
check xxd
check openssl
check 7z
check exiftool
check rg
check jq
check r2
check jadx
check fls
check ewfmount
check tshark
check python3
check pip3

# Python package check
echo ""
echo "  Python 包检查:"
for pkg in Cryptodome sqlcipher3 openpyxl pandas evtx volatility3; do
    python3 -c "import $pkg" 2>/dev/null && \
        printf "  [OK]   %s\n" "$pkg" || \
        printf "  [MISS] %s\n" "$pkg"
done

echo ""
echo "=========================================="
echo "  安装完成！"
echo "  激活 venv: source $VENV_DIR/bin/activate"
echo "=========================================="
