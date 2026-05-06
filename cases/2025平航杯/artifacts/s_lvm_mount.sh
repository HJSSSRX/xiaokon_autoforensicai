#!/bin/bash
echo '=== LVM scan ==='
sudo pvscan 2>&1 | head -5
sudo vgscan 2>&1 | head -5
sudo lvscan 2>&1 | head -10
sudo vgchange -ay 2>&1 | head -5

echo
echo '=== LV list ==='
sudo lvs 2>&1

echo
echo '=== Mount root LV ==='
sudo mkdir -p /mnt/server /mnt/server_boot
LVPATH=$(sudo lvs --noheadings -o lv_path | head -1 | tr -d ' ')
echo "LV path: $LVPATH"
sudo mount -o ro "$LVPATH" /mnt/server 2>&1
sudo mount -o ro /dev/nbd0p1 /mnt/server_boot 2>&1

echo
echo '=== Server root listing ==='
ls /mnt/server/ 2>&1
echo
echo '=== /etc/os-release ==='
cat /mnt/server/etc/os-release 2>&1 | head -10
echo
echo '=== /etc/hostname ==='
cat /mnt/server/etc/hostname 2>&1