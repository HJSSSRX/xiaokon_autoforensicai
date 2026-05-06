#!/bin/bash
U="/mnt/win_c/Users/起早王"
SYS="/mnt/win_c/Windows/System32"

echo '=== C01 USB 序列号 (SYSTEM hive) ==='
sudo ls -la $SYS/config/SYSTEM 2>&1
# reglookup or chntpw 解 registry
which hivexsh reglookup chntpw 2>&1

echo
echo '=== C03 默认浏览器 (NTUSER.DAT UserChoice) ==='
sudo ls -la "$U/NTUSER.DAT"
echo
echo '=== C05 系统最后关机时间 (SYSTEM ShutdownTime) ==='
echo '需 hivex 或 reglookup'

echo
echo '=== C02 便签 (Sticky Notes) ==='
sudo find "$U/AppData/Local/Packages" -name '*Microsoft.MicrosoftStickyNotes*' -maxdepth 2 2>&1 | head
sudo ls "$U/AppData/Local/Packages/Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe/LocalState" 2>&1 | head

echo
echo '=== C04 浏览器历史（小说）==='
sudo find "$U/AppData/Local" -iname 'History' -maxdepth 5 2>&1 | head
sudo find "$U/AppData" -iname 'places.sqlite' 2>&1 | head

echo
echo '=== C06 日记 ==='
sudo ls "$U/Desktop" 2>&1 | head
sudo ls "$U/Documents" 2>&1 | head