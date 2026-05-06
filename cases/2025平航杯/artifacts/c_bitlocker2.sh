#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== WYWZ 目录 ==='
sudo ls -la "$U/Downloads/WYWZ" 2>&1
sudo find "$U/Downloads/WYWZ" -type f 2>&1 | head -30

echo
echo '=== 回收站 ==='
sudo find /mnt/win_c/\$Recycle.Bin -type f 2>&1 | head -30
# Recycle.Bin 的 $I 元数据 + $R 原始文件
sudo find /mnt/win_c -maxdepth 5 -iname '*BitLocker*.txt' 2>/dev/null | head
sudo find /mnt/win_c -maxdepth 5 -iname '*121E1B22*' 2>/dev/null | head

echo
echo '=== 全盘搜 BitLocker 密钥格式 (6*8-6 = xxxxxx-xxxxxx-... 8段) ==='
# 这种搜索太慢，改用 grep
sudo grep -rlE '^[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}$' /mnt/win_c/Users 2>/dev/null | head
echo '-- 搜 identifier 121E1B22 --'
sudo grep -rla '121E1B22' /mnt/win_c/Users 2>/dev/null | head -10

echo
echo '=== SYSTEM hive BitLocker info ==='
# BitLocker 保护项在 Policies\Microsoft\FVE 也可能在 SAM/Tpm
sudo find /mnt/win_c -maxdepth 5 -iname '*.BEK' 2>/dev/null | head