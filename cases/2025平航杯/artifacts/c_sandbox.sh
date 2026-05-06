#!/bin/bash
SB='/mnt/win_c/Sandbox'

echo '=== Sandbox 根 ==='
sudo ls -la "$SB" 2>&1
echo
sudo ls "$SB/起早王" 2>&1 | head -40
echo
echo '-- diary --'
sudo ls -la "$SB/起早王/diary" 2>&1 | head -30
echo
sudo find "$SB/起早王/diary" -type f 2>&1 | head -20

echo
echo '=== Sandbox/起早王 全子目录 ==='
sudo find "$SB/起早王" -maxdepth 3 -type d 2>&1 | head -40

echo
echo '=== 里面的用户文件 ==='
sudo find "$SB/起早王" -maxdepth 6 -iname 'SillyTavern*' -o -iname 'neo4j*' -o -iname 'roop*' -o -iname '*facefusion*' 2>/dev/null | head -20