#!/bin/bash
D='/mnt/win_c/Sandbox/起早王/diary/user/current/.rednotebook/data'

echo '=== C06 日记文件列表 ==='
sudo ls -la $D

echo
echo '=== 2025-02.txt 内容 ==='
sudo cat "$D/2025-02.txt" 2>&1 | head -50

echo
echo '=== 2025-03.txt 首 20 行 ==='
sudo cat "$D/2025-03.txt" 2>&1 | head -20

echo
echo '=== C07-C16 全盘找工具 ==='
sudo find /mnt/win_c -maxdepth 5 -type d \( -iname 'SillyTavern*' -o -iname 'neo4j*' -o -iname 'roop*' -o -iname '*facefusion*' -o -iname '*faceswap*' -o -iname '*deepface*' \) 2>/dev/null | head -30

echo
echo '=== 顶层 C: 目录全貌 ==='
sudo ls /mnt/win_c 2>&1
echo
echo '-- Model --'
sudo ls /mnt/win_c/Model 2>&1 | head
echo '-- paddle --'
sudo ls /mnt/win_c/paddle 2>&1 | head
echo '-- ssl_key --'
sudo ls /mnt/win_c/ssl_key 2>&1 | head
echo '-- Program Files --'
sudo ls '/mnt/win_c/Program Files' 2>&1 | head -30
echo '-- ProgramData --'
sudo ls /mnt/win_c/ProgramData 2>&1 | head -30