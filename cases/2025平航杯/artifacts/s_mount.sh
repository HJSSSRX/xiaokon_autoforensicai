#!/bin/bash
VMDK="/mnt/f/TEXT(important)/Jian cai/2025平航杯/export-disk0-000002.vmdk"

echo '=== qemu-img info ==='
qemu-img info "$VMDK" 2>&1 | head -15

echo
echo '=== virt-filesystems ==='
sudo virt-filesystems -a "$VMDK" --all --long --uuid 2>&1 | head -20

echo
echo '=== Mount via guestmount (read-only) ==='
sudo mkdir -p /mnt/server
sudo guestmount -a "$VMDK" -i --ro /mnt/server 2>&1 | head -10
echo
echo '=== Mounted root ==='
ls /mnt/server/ 2>&1 | head -20