#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== 全盘搜日记 ==='
sudo find /mnt/win_c -maxdepth 6 -iname '*日记*' 2>/dev/null | head -20
sudo find /mnt/win_c -maxdepth 6 -iname '*diary*' 2>/dev/null | head -20

echo
echo '=== WeChat Files 详查 ==='
sudo ls -la "$U/Documents/WeChat Files" 2>&1
sudo ls "$U/Documents/WeChat Files/All Users" 2>&1

echo
echo '=== WPS 最近文档 & 云档 ==='
sudo find "$U" -name '*.wps' -o -name '*.docx' -o -iname 'recent*' 2>/dev/null | head -20
sudo find "$U/AppData/Roaming/Kingsoft" -type f 2>/dev/null | head -20

echo
echo '=== 桌面文件详查（含隐藏）==='
sudo ls -la "$U/Desktop" 2>&1
echo
sudo ls -la "$U/Desktop/倩倩的生日礼物" 2>&1

echo
echo '=== C07-C09 SillyTavern ==='
sudo find /mnt/win_c -maxdepth 5 -iname 'SillyTavern*' 2>/dev/null | head
sudo find /mnt/win_c -iname 'SillyTavern' -type d 2>/dev/null | head

echo
echo '=== C10-C12 AI face (ROOP/DeepFaceLab/FaceSwap) ==='
sudo find /mnt/win_c -maxdepth 4 -iname 'roop*' -o -iname '*faceswap*' -o -iname '*deepface*' -o -iname '*facefusion*' 2>/dev/null | head

echo
echo '=== C13-C16 neo4j ==='
sudo find /mnt/win_c -maxdepth 5 -iname 'neo4j*' -type d 2>/dev/null | head