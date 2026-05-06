#!/bin/bash
W='/mnt/win_c/Users/起早王/wife/wife'

echo '=== _storage 文件类型 ==='
for f in $W/data/_storage/*; do
    echo "## $(basename $f)  size=$(stat -c%s $f)"
    sudo file $f
    sudo head -c 200 $f
    echo
done

echo
echo '=== SillyTavern post-install.js / users.js ==='
sudo grep -rlE 'userHandle|user_handle|createdAt|created_at' $W/src 2>/dev/null | head -5
sudo find $W/src -iname '*user*' -type f 2>&1 | head

echo
echo '=== src/users.js ==='
sudo cat $W/src/users.js 2>&1 | head -30
sudo cat $W/src/users-api.js 2>&1 | head -30

echo
echo '=== 搜 akari / 小倩 字串 - 确认 ai 女友角色 ==='
# C09 ai 女友聊天调用的模型，看看 chat 文件
CHAT=$(sudo find "$W/data/default-user/chats/小倩" -type f 2>/dev/null | head -1)
echo "Chat file: $CHAT"
[ -n "$CHAT" ] && sudo head -c 2000 "$CHAT"