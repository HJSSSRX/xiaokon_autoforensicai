#!/usr/bin/env bash
# FIC2026 P0 工具批量安装（apt 仓库 + pip）
# Usage: bash fic_install_p0.sh
set +e

PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== [1/5] apt update ====="
SUDO apt-get update -y 2>&1 | tail -5

echo ""
echo "===== [2/5] 安装 P0 apt 包 ====="
# 分类批量装，便于看哪个失败
SUDO apt-get install -y \
    default-mysql-client \
    qemu-utils \
    vmfs-tools \
    binwalk \
    foremost \
    testdisk \
    poppler-utils \
    hashcat hydra john \
    fcrackzip \
    ngrep \
    apktool \
    aapt \
    libimage-exiftool-perl \
    p7zip-rar \
    unrar-free \
    cabextract \
    sleuthkit \
    libewf-tools \
    afflib-tools \
    bulk-extractor \
    yara \
    radare2 \
    2>&1 | tail -20

echo ""
echo "===== [3/5] 安装 pip 包 ====="
source $HOME/.venv-forensics/bin/activate 2>/dev/null
pip install --quiet \
    pefile \
    yara-python \
    pyOpenSSL \
    cryptography \
    pycryptodome \
    impacket \
    pypykatz \
    olefile \
    oletools \
    2>&1 | tail -10

echo ""
echo "===== [4/5] 验证安装 ====="
for t in mysql qemu-img vmfs-fuse binwalk foremost photorec pdfinfo pdftotext hashcat hydra john fcrackzip ngrep apktool yara r2; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "OK : $t"
  else
    echo "-- : $t (still missing)"
  fi
done

echo ""
echo "===== [5/5] Done. 接下来手动装 jadx/mongosh/zeek（不在 apt 仓库）====="
