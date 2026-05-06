#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== C02 plum.sqlite schema ==='
sqlite3 /tmp/plum.sqlite '.schema'
echo
for t in $(sqlite3 /tmp/plum.sqlite '.tables'); do
    echo "-- $t --"
    sqlite3 /tmp/plum.sqlite "SELECT count(*) FROM $t;"
done

echo
echo '=== C06 日记 拓展搜索 ==='
echo '-- 倩倩的生日礼物 dir --'
sudo ls -la "$U/Desktop/倩倩的生日礼物" 2>&1 | head -20
echo
echo '-- WeChat Files --'
sudo ls "$U/Documents/WeChat Files" 2>&1 | head
echo
echo '-- WPSDrive --'
sudo ls "$U/Documents/WPSDrive" 2>&1 | head -20
echo
echo '-- KingsoftData (WPS 本地) --'
sudo ls "$U/Documents/KingsoftData" 2>&1 | head
sudo find "$U/Documents/KingsoftData" -type f 2>&1 | head -30

echo
echo '-- Browse all txt/docx/md on desktop and documents --'
sudo find "$U/Desktop" "$U/Documents" -maxdepth 3 \( -iname '*.txt' -o -iname '*.docx' -o -iname '*.doc' -o -iname '*.md' -o -iname '*.rtf' \) 2>&1 | head -20

echo
echo '-- Check OneDrive / 文档 --'
sudo find "$U" -maxdepth 2 -type d 2>&1 | head