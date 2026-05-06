#!/bin/bash
set -e
E01='/mnt/f/TEXT(important)/Jian cai/2025平航杯/window.e01'

sudo mkdir -p /mnt/e01_raw /mnt/win
echo '=== ewfmount (FUSE) ==='
mountpoint -q /mnt/e01_raw || sudo ewfmount "$E01" /mnt/e01_raw
ls -la /mnt/e01_raw

echo
echo '=== mmls partition table ==='
sudo mmls /mnt/e01_raw/ewf1

echo
echo '=== ewfinfo quick ==='
ewfinfo "$E01" 2>/dev/null | head -30