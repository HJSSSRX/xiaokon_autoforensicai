#!/bin/bash
U='/mnt/win_c/Users/起早王'
SN="$U/AppData/Local/Packages/Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe/LocalState"

echo '=== StickyNotes LocalState ==='
sudo ls -la "$SN" 2>&1
echo
echo '=== plum.sqlite 完整复制 (含 wal/shm) ==='
sudo cp "$SN/plum.sqlite" /tmp/plum.sqlite
sudo cp "$SN/plum.sqlite-wal" /tmp/plum.sqlite-wal 2>/dev/null
sudo cp "$SN/plum.sqlite-shm" /tmp/plum.sqlite-shm 2>/dev/null
ls -la /tmp/plum.sqlite*
echo
file /tmp/plum.sqlite
xxd /tmp/plum.sqlite | head -3
echo
echo '-- try open --'
sqlite3 /tmp/plum.sqlite '.tables' 2>&1
sqlite3 /tmp/plum.sqlite '.schema' 2>&1 | head -30

echo
echo '=== 搜 sqlite 文件含 Note 表 ==='
sudo find "$U/AppData" -name 'plum.sqlite*' 2>/dev/null

echo
echo '=== 15cb...session 文件 ==='
sudo ls -la "$SN"/*.session* 2>&1 | head
sudo cat "$SN/15cbbc93e90a4d56bf8d9a29305b8981.storage.session" 2>&1 | head -c 500