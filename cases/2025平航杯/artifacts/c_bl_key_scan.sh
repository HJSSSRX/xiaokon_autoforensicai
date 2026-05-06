#!/bin/bash

echo '=== pagefile.sys 扫 48 位 BitLocker 密钥 ==='
# BitLocker 密钥格式: XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX (每段6位数字)
# 2.5GB 直接 grep 太慢，先 strings 再 grep
# strings 默认 min-len=4，改为 55 (48 digit + 7 dash)
sudo strings -n 55 /mnt/win_c/pagefile.sys | grep -E '^[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}$' | head

echo
echo '-- strings -el (UTF-16) 同样扫 --'
sudo strings -el -n 55 /mnt/win_c/pagefile.sys | grep -E '^[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}$' | head

echo
echo '=== hiberfile.sys check ==='
sudo ls -la /mnt/win_c/hiberfil.sys 2>&1

echo
echo '=== swapfile.sys 扫 ==='
sudo strings -n 55 /mnt/win_c/swapfile.sys | grep -E '^[0-9]{6}-' | head
sudo strings -el -n 55 /mnt/win_c/swapfile.sys | grep -E '^[0-9]{6}-' | head

echo
echo '=== Search whole C drive (跳过大文件) for 48-digit key - 仅小 txt/log/db ==='
# 在非二进制文件找 可能残留的 key
sudo grep -raEh '[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}-[0-9]{6}' /mnt/win_c/Users 2>/dev/null | head