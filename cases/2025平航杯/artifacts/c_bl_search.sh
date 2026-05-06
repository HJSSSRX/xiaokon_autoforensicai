#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== Windows Search 索引 Windows.edb ==='
sudo find /mnt/win_c -maxdepth 6 -iname 'Windows.edb' 2>/dev/null | head
sudo find /mnt/win_c -maxdepth 6 -iname '*.edb' 2>/dev/null | head -10

echo
echo '=== Windows Search 的 cache ==='
sudo ls "$U/AppData/Local/Packages/Microsoft.Windows.Search_cw5n1h2txyewy/LocalState" 2>&1 | head
sudo find "$U/AppData/Local/Packages/Microsoft.Windows.Search_cw5n1h2txyewy" -type f 2>&1 | head -20

echo
echo '=== AppCache txt 全文 (可能含密钥) ==='
sudo strings "$U/AppData/Local/Packages/Microsoft.Windows.Search_cw5n1h2txyewy/LocalState/DeviceSearchCache/AppCache133890722317075819.txt" 2>&1 | grep -aE '[0-9]{6}-[0-9]{6}' | head

echo
echo '=== SearchData ==='
SEARCH="$U/AppData/Local/Packages/Microsoft.Windows.Search_cw5n1h2txyewy"
sudo find $SEARCH -name '*.db' 2>&1 | head
# CortanaCoreDb
sudo find /mnt/win_c -iname 'CortanaCoreDb.dat' 2>/dev/null | head

echo
echo '=== MFT + USN journal ==='
sudo ls -la /mnt/win_c/\$MFT 2>&1
sudo ls -la /mnt/win_c/\$Extend/\$UsnJrnl 2>&1

echo
echo '=== bulk_extractor 可用? ==='
which bulk_extractor 2>&1