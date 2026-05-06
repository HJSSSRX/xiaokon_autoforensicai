#!/bin/bash
LOOP=$(sudo losetup -f)
echo "using $LOOP"
sudo losetup -r -o 63786086400 --sizelimit 21473787904 $LOOP /mnt/e01_raw/ewf1
sudo mount -o ro,show_sys_files $LOOP /mnt/win_e
sudo ls /mnt/win_e | head -30
echo
echo '=== /mnt/win_e facefusion ==='
sudo ls /mnt/win_e | grep -i facefusion
sudo ls /mnt/win_e | grep -i neo4j