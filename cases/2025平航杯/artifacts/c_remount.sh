#!/bin/bash
set -e
E01="/mnt/f/TEXT(important)/Jian cai/2025平航杯/window.e01"

# 重挂
sudo mkdir -p /mnt/e01_raw /mnt/win_c
mountpoint -q /mnt/e01_raw || sudo ewfmount "$E01" /mnt/e01_raw
mountpoint -q /mnt/win_c || sudo mount -o ro,loop,offset=53477376,show_sys_files,streams_interface=windows /mnt/e01_raw/ewf1 /mnt/win_c
echo 'C 盘 OK:'
sudo ls /mnt/win_c | head -5