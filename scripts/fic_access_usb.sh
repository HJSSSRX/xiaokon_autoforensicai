#!/usr/bin/env bash
# Access USB evidence and search for key files

PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw 2>/dev/null | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "=== USB Directory ==="
ls -la /tmp/fic2026/usb/

echo ""
echo "=== USB ewf Directory (sudo) ==="
SUDO ls -la /tmp/fic2026/usb/ewf/

echo ""
echo "=== Find SampleVC.exe ==="
SUDO find /tmp/fic2026/usb -name 'SampleVC*' 2>/dev/null

echo ""
echo "=== Find .et files ==="
SUDO find /tmp/fic2026/usb -name '*.et' 2>/dev/null

echo ""
echo "=== All files in USB (top 50) ==="
SUDO find /tmp/fic2026/usb -type f 2>/dev/null | head -50
