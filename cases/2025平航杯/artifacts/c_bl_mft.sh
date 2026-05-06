#!/bin/bash

echo '=== 扫 $MFT 找 BitLocker 密钥模式 ==='
# strings -el (UTF-16 LE) 因为 BitLocker 密钥 TXT 是 Unicode
sudo strings -el -n 55 /mnt/win_c/\$MFT | grep -E '[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}' | head

echo
echo '-- 8-bit 搜 --'
sudo strings -n 55 /mnt/win_c/\$MFT | grep -E '[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}' | head

echo
echo '-- UTF-16 LE 更短匹配 (可能前缀有字) --'
sudo strings -el -n 20 /mnt/win_c/\$MFT | grep -E '[0-9]{6}-[0-9]{6}' | head -20

echo
echo '=== 全盘 NTFS undeleted 搜 (scraping raw) ==='
# BitLocker key identifier 121E1B22 在 txt 文件头
# "BitLocker Drive Encryption recovery key" 是标准 Windows txt 的开头
sudo strings -el /mnt/win_c/\$MFT 2>/dev/null | grep -iE 'BitLocker|recovery key' | head -10

echo
echo '=== 扫整个 ewf1 (raw e01 image) ==='
# 这会扫整盘 80GB，可能要几分钟。先限制大小
sudo timeout 180 strings -el -n 55 /mnt/e01_raw/ewf1 2>/dev/null | grep -m 1 -E '^[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}$' &
STR_PID=$!
# 并行 8-bit 扫
sudo timeout 180 strings -n 55 /mnt/e01_raw/ewf1 2>/dev/null | grep -m 1 -E '^[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}$' &
STR2_PID=$!
wait $STR_PID $STR2_PID