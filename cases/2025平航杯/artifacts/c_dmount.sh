#!/bin/bash

echo '=== 日记文件搜 RedNotebook journal data ==='
sudo find /mnt/win_c/Sandbox -iname '*.txt' -path '*RedNotebook*' 2>&1 | head
sudo find /mnt/win_c/Sandbox/起早王/diary/user -type f 2>&1 | head -30
# RedNotebook 默认存 .rednotebook 或 AppData/Roaming/RedNotebook
sudo find /mnt/win_c/Sandbox -iname 'month*.txt' -o -name 'journal*' 2>&1 | head

echo
echo '=== 挂 D 盘 via losetup --partscan ==='
sudo losetup -D 2>/dev/null
RAW=/mnt/e01_raw/ewf1
# 找空闲 loop
LOOP=$(sudo losetup -f)
echo "Using $LOOP"
sudo losetup -r -P "$LOOP" "$RAW"
sleep 1
ls -la ${LOOP}p*
sudo mkdir -p /mnt/win_c2 /mnt/win_d
# p2 = 主 C（或许和 /mnt/win_c 冲突），p3 = D
mountpoint -q /mnt/win_d || sudo mount -o ro,show_sys_files "${LOOP}p3" /mnt/win_d
ls /mnt/win_d 2>&1 | head -30

echo
echo '=== D 盘用户目录 ==='
sudo ls /mnt/win_d 2>&1 | head -40