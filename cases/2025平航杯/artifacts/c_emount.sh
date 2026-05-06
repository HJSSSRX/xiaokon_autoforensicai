#!/bin/bash
set -e

# 清 loop
sudo losetup -a

# 用 offset mount - slot 007 起 124581888*512 = 63786086400
OFF=63786086400
SIZE=$((41940992*512))
echo "offset=$OFF  size=$SIZE"

# 需要 sizelimit 避免 loop 读到分区尾 (offset 到盘尾 = 0x275E00000)
sudo mkdir -p /mnt/win_e
mountpoint -q /mnt/win_e || sudo mount -o ro,loop,offset=$OFF,sizelimit=$SIZE,show_sys_files /mnt/e01_raw/ewf1 /mnt/win_e 2>&1

echo
echo '=== /mnt/win_e ==='
sudo ls /mnt/win_e 2>&1 | head -30