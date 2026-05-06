#!/bin/bash
VMDK="/mnt/f/TEXT(important)/Jian cai/2025平航杯/export-disk0-000002.vmdk"
PWFILE=/mnt/e/项目/自动化取证/cases/.wsl_pw

echo '=== modprobe nbd ==='
sudo modprobe nbd max_part=16 2>&1
ls /dev/nbd* 2>/dev/null | head -5

echo
echo '=== qemu-nbd connect ==='
sudo qemu-nbd -d /dev/nbd0 2>/dev/null
sudo qemu-nbd -r -c /dev/nbd0 "$VMDK" 2>&1
sleep 2

echo
echo '=== partition table ==='
sudo fdisk -l /dev/nbd0 2>&1 | head -20

echo
echo '=== try mount partitions ==='
for p in /dev/nbd0p1 /dev/nbd0p2 /dev/nbd0p3; do
    [ -b "$p" ] && {
        echo "-- $p --"
        sudo blkid "$p"
    }
done