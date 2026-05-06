#!/bin/bash
set -e
E01="/mnt/f/TEXT(important)/Jian cai/2025平航杯/window.e01"

sudo mkdir -p /mnt/e01_raw /mnt/win_c
mountpoint -q /mnt/e01_raw || sudo ewfmount "$E01" /mnt/e01_raw
mountpoint -q /mnt/win_c || sudo mount -o ro,loop,offset=53477376,show_sys_files,streams_interface=windows /mnt/e01_raw/ewf1 /mnt/win_c

echo '=== crack 相关文件 ==='
sudo find /mnt/win_c -maxdepth 5 -iname '*crack*' 2>/dev/null

echo
echo '=== Downloads 内容 ==='
sudo ls -la "/mnt/win_c/Users/起早王/Downloads" 2>&1 | head -30