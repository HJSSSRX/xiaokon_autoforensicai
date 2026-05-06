#!/bin/bash
echo '=== Tools ==='
for t in qemu-img qemu-nbd guestmount fdisk mmls fls virt-filesystems guestfish; do
    if command -v $t >/dev/null 2>&1; then echo "OK: $t"; else echo "MISS: $t"; fi
done
echo
echo '=== nbd module ==='
lsmod 2>/dev/null | grep -E '^nbd'
ls /dev/nbd* 2>/dev/null | head -3
echo
echo '=== vmdk file ==='
ls -la "/mnt/f/TEXT(important)/Jian cai/2025平航杯/" 2>&1 | head -10
echo
echo '=== qemu-img info on vmdk ==='
qemu-img info "/mnt/f/TEXT(important)/Jian cai/2025平航杯/export-disk0-000002.vmdk" 2>&1 | head -20