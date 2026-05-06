#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== ActivitiesCache.db 内含 BitLocker 文件 context ==='
sudo cp "$U/AppData/Local/ConnectedDevicesPlatform/L.起早王/ActivitiesCache.db" /tmp/act.db
sudo cp "$U/AppData/Local/ConnectedDevicesPlatform/L.起早王/ActivitiesCache.db-wal" /tmp/act.db-wal 2>/dev/null
sqlite3 /tmp/act.db '.tables'
echo
sqlite3 /tmp/act.db "SELECT ActivityType, Payload FROM Activity WHERE Payload LIKE '%121E1B22%' OR Payload LIKE '%BitLocker%' LIMIT 10;" | head -c 3000

echo
echo '=== AppCache 内的搜索结果 ==='
sudo strings "$U/AppData/Local/Packages/Microsoft.Windows.Search_cw5n1h2txyewy/LocalState/DeviceSearchCache/AppCache133890722317075819.txt" | grep -aE 'BitLocker|121E1B22|[0-9]{6}-[0-9]{6}' | head

echo
echo '=== 剪贴板/WinClip 历史 ==='
sudo find "$U/AppData/Local/Microsoft/Windows/Clipboard" -type f 2>&1 | head
sudo ls "$U/AppData/Local/ConnectedDevicesPlatform" 2>&1 | head

echo
echo '=== USN / MFT 中是否有 txt 痕迹 ==='
sudo find /mnt/win_c -maxdepth 6 -iname '*.txt' -path '*Downloads*' 2>&1 | head

echo
echo '=== Volume Shadow Copies ==='
sudo ls '/mnt/win_c/System Volume Information' 2>&1 | head -30