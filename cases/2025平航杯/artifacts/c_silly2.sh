#!/bin/bash
W='/mnt/win_c/Users/起早王/wife/wife'

echo '=== 用户管理文件 ==='
sudo find "$W" -name 'users.json' -o -name 'users.db*' -o -name 'settings*.json' 2>&1 | head
sudo ls "$W/data/_storage" 2>&1 | head
sudo find "$W/data/_storage" -type f 2>&1 | head -20

echo
echo '=== 找 "起早王" 字串 ==='
sudo grep -rl '起早王' "$W/data" 2>/dev/null | head -10

echo
echo '=== 每用户目录 ==='
for u in default-user 小朱 恋恋 灵姐; do
    echo "## $u chats:"
    sudo ls "$W/data/$u/chats" 2>&1 | head
    echo
    echo "## $u characters:"
    sudo ls "$W/data/$u/characters" 2>&1 | head
done

echo
echo '=== _uploads ==='
sudo ls "$W/data/_uploads" 2>&1 | head

echo
echo '=== users.json candidates ==='
sudo find "$W" -iname '*user*.json' -maxdepth 4 2>&1 | head