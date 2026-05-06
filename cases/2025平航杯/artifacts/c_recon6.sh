#!/bin/bash

echo '=== /usr 目录 ==='
sudo ls /mnt/win_c/usr 2>&1 | head -30

echo
echo '=== Model/gguf (AI 模型 C09) ==='
sudo ls -la /mnt/win_c/Model/gguf 2>&1 | head -30
sudo find /mnt/win_c/Model -type f 2>&1 | head -20

echo
echo '=== 深搜 SillyTavern / neo4j / roop ==='
sudo find /mnt/win_c -maxdepth 6 -type d \( -iname 'SillyTavern*' -o -iname 'neo4j*' -o -iname 'roop*' -o -iname '*facefusion*' -o -iname '*faceswap*' \) 2>/dev/null | head -30

echo
echo '=== WindowsApps ==='
sudo ls '/mnt/win_c/Program Files/WindowsApps' 2>&1 | head -30

echo
echo '=== Users/起早王/AppData 全子目录 ==='
sudo find '/mnt/win_c/Users/起早王/AppData' -maxdepth 3 -type d 2>&1 | grep -iE 'silly|neo4j|roop|face|tavern|java|llm|rag' | head -30

echo
echo '=== 搜所有 neo4j / sillytavern 文件 ==='
sudo find /mnt/win_c -iname 'neo4j.conf' 2>/dev/null | head
sudo find /mnt/win_c -iname 'SillyTavern*.lnk' 2>/dev/null | head
sudo find /mnt/win_c -iname 'config.yaml' 2>/dev/null | head

echo
echo '=== 快捷方式历史 ==='
sudo ls '/mnt/win_c/Users/起早王/AppData/Roaming/Microsoft/Windows/Recent' 2>&1 | head -30
sudo ls '/mnt/win_c/ProgramData/Microsoft/Windows/Start Menu/Programs' 2>&1 | head -30