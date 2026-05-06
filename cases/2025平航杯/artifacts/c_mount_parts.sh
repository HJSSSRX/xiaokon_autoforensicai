#!/bin/bash
set -e
sudo mkdir -p /mnt/win_c /mnt/win_d
RAW=/mnt/e01_raw/ewf1

# 主 C 盘: offset=104448*512=53477376
OFF_C=53477376
# 其他 NTFS: offset=124581888*512=63786086400
OFF_D=63786086400

mountpoint -q /mnt/win_c || sudo mount -o ro,loop,offset=$OFF_C,show_sys_files,streams_interface=windows "$RAW" /mnt/win_c
mountpoint -q /mnt/win_d || sudo mount -o ro,loop,offset=$OFF_D,show_sys_files,streams_interface=windows "$RAW" /mnt/win_d 2>&1 || echo 'D mount failed'

echo '=== /mnt/win_c root ==='
sudo ls /mnt/win_c | head -30
echo
echo '=== /mnt/win_d root ==='
sudo ls /mnt/win_d 2>&1 | head -30
echo
echo '=== Users dir ==='
sudo ls "/mnt/win_c/Users" 2>&1 | head