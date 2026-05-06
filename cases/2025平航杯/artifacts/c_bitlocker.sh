#!/bin/bash

echo '=== BitLocker recovery key 相关文件 ==='
sudo find /mnt/win_c -iname '*BitLocker*' 2>/dev/null | head -20

echo
echo '=== BitLocker 恢复密钥 lnk target ==='
sudo strings '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent/BitLocker 恢复密钥 121E1B22-A1A7-4A54-A8D4-799265C402CF.lnk' 2>/dev/null | head -20

echo
echo '=== 恢复密钥 txt ==='
sudo find /mnt/win_c -iname '*recovery*key*' -o -iname '*BitLocker*key*' 2>/dev/null | head
sudo find /mnt/win_c -iname '*121E1B22*' 2>/dev/null | head

echo
echo '=== 搜 48 位数字串 (BitLocker recovery key pattern XXXXXX-XXXXXX-*) ==='
sudo grep -rEl '[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}' /mnt/win_c/Users/起早王 2>/dev/null | head -5

echo
echo '=== 桌面/文档的 txt ==='
sudo find /mnt/win_c/Users/起早王/Desktop /mnt/win_c/Users/起早王/Documents -name '*.txt' 2>/dev/null | head