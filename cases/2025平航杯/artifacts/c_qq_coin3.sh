#!/bin/bash
U='/mnt/win_c/Users/起早王'
A1=1978a452c8066b57cc25816a9637f1146253be4a
A2=c4bfccb1668d6e464f33a76badd8c8d7d341e04a

CACHE="$U/AppData/Local/Microsoft/Edge/User Data/Default/Cache/Cache_Data"

echo '=== Cache 搜两合约 ==='
sudo grep -rla "$A1" "$CACHE" 2>/dev/null | head
echo '--- A2 ---'
sudo grep -rla "$A2" "$CACHE" 2>/dev/null | head

echo
echo '=== Cache 搜关键字 ==='
sudo grep -rla -E 'QianQian|倩倩|totalSupply' "$CACHE" 2>/dev/null | head

echo
echo '=== Code Cache (JS/WASM) ==='
CC="$U/AppData/Local/Microsoft/Edge/User Data/Default/Code Cache/js"
sudo grep -rla "$A1\|$A2" "$CC" 2>/dev/null | head

echo
echo '=== 全盘 grep 两合约地址 ==='
sudo grep -rlaI "$A1" /mnt/win_c/Users/起早王 2>/dev/null | head
echo '---'
sudo grep -rlaI "$A2" /mnt/win_c/Users/起早王 2>/dev/null | head

echo
echo '=== Remix IDE / Hardhat / Solidity 项目 ==='
sudo find /mnt/win_c -maxdepth 6 -type d \( -iname '*solidity*' -o -iname '*hardhat*' -o -iname '*remix*' -o -iname '*truffle*' -o -iname '*foundry*' \) 2>/dev/null | head

echo
echo '=== .sol 合约文件 ==='
sudo find /mnt/win_c -iname '*.sol' 2>/dev/null | head