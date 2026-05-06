#!/bin/bash
sudo losetup -d /dev/loop1 2>/dev/null
# Correct offset = 124581888 * 512 = 63785926656
LOOP=$(sudo losetup -f)
echo "using $LOOP"
sudo losetup -r -o 63785926656 --sizelimit 21473787904 $LOOP /mnt/e01_raw/ewf1
echo '-- probe NTFS --'
sudo hexdump -C -n 16 $LOOP
sudo blkid $LOOP
echo
echo '-- mount --'
sudo mount -t ntfs-3g -o ro,show_sys_files,streams_interface=windows $LOOP /mnt/win_e && echo OK && ls /mnt/win_e | head -30