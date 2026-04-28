#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')

echo "$PW" | sudo -S apt-get install -y \
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
    afflib-tools \
    yara \
    radare2 \
    2>&1 | tail -25

echo ""
echo "===== verify ====="
for t in mysql qemu-img vmfs-fuse binwalk foremost photorec pdfinfo pdftotext hashcat hydra john fcrackzip ngrep apktool yara r2 bulk_extractor; do
  if command -v "$t" >/dev/null 2>&1; then echo "OK : $t"; else echo "-- : $t"; fi
done
