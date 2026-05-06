#!/bin/bash
U='/mnt/win_c/Users/起早王'

echo '=== C02 便签 plum.sqlite ==='
STICKY="$U/AppData/Local/Packages/Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe/LocalState/plum.sqlite"
sudo cp "$STICKY" /tmp/plum.sqlite 2>&1
sqlite3 /tmp/plum.sqlite '.tables'
echo '-- Note count --'
sqlite3 /tmp/plum.sqlite "SELECT count(*) FROM Note;"
echo '-- Note contents (strip rtf) --'
sqlite3 /tmp/plum.sqlite "SELECT Id, CreatedAt, substr(Text,1,300) FROM Note;" 2>&1 | head -30

echo
echo '=== C04 Edge History ==='
HIST="$U/AppData/Local/Microsoft/Edge/User Data/Default/History"
sudo cp "$HIST" /tmp/edge_hist.sqlite 2>&1
echo '-- 小说相关 url --'
sqlite3 /tmp/edge_hist.sqlite "SELECT url, title, visit_count FROM urls WHERE title LIKE '%小说%' OR url LIKE '%novel%' OR title LIKE '%章%' ORDER BY last_visit_time DESC LIMIT 20;"
echo
echo '-- top titles --'
sqlite3 /tmp/edge_hist.sqlite "SELECT title, visit_count, url FROM urls WHERE visit_count > 2 ORDER BY visit_count DESC LIMIT 30;"

echo
echo '=== C06 日记 ==='
sudo ls "$U/Desktop" "$U/Documents" 2>&1
echo '-- find diary/日记 file --'
sudo find "$U" -iname '*日记*' -o -iname '*diary*' 2>/dev/null | head -20
sudo find "$U/Desktop" -type f 2>/dev/null | head -30