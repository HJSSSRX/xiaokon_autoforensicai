#!/bin/bash
BAK="/tmp/phone/20250415_181118/Google Service Framework(com.example.reverseshell2).bak"
if [ ! -f "$BAK" ]; then
    # extract trojan bak from zip
    cd /tmp/phone
    unzip -o "/mnt/f/TEXT(important)/Jian cai/2025平航杯/20250415_181118.zip" \
      '*reverseshell2*' 2>&1 | tail -3
fi
ls -la "$BAK"
echo '=== first 256 bytes hex ==='
xxd "$BAK" | head -16
echo '=== file type ==='
file "$BAK"
echo '=== search for tar magic or PK ==='
xxd "$BAK" | grep -m 5 -E 'ustar|PK\.\.|\.PNG'
echo '=== bytes at various offsets ==='
for off in 0 16 32 64 128 256 512 1024; do
    echo "-- offset $off --"
    dd if="$BAK" bs=1 skip=$off count=16 2>/dev/null | xxd
done