#!/bin/bash
W='/mnt/win_c/Users/起早王/wife/wife'

echo '=== SillyTavern root ==='
sudo ls -la "$W" 2>&1 | head -40
echo
echo '=== config.yaml ==='
sudo cat "$W/config.yaml" 2>&1 | head -80

echo
echo '=== data/ 用户 ==='
sudo ls "$W/data" 2>&1 | head -20
sudo find "$W/data" -maxdepth 3 -type d 2>&1 | head -30

echo
echo '=== 起早王 用户目录 ==='
sudo find "$W/data" -iname '*起早王*' 2>&1 | head

echo
echo '=== chats jsonl ==='
sudo find "$W/data" -name '*.jsonl' 2>&1 | head

echo
echo '=== characters (角色) ==='
sudo find "$W/data" -name 'characters' -type d 2>&1 | head
sudo find "$W/data" -iname '*character*' 2>&1 | head