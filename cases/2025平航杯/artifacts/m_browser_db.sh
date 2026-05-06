#!/bin/bash
DB=/tmp/phone/browser/apps/com.android.browser/db/browser2.db
echo '=== tables ==='
sqlite3 "$DB" '.tables'
echo
echo '=== history rows ==='
sqlite3 -header "$DB" "SELECT url, title, visits, datetime(date/1000,'unixepoch','+8 hours') FROM history ORDER BY date DESC LIMIT 30;" 2>&1
echo
echo '=== bookmark/downloads ==='
sqlite3 -header "$DB" "SELECT name FROM sqlite_master WHERE type='table';" 2>&1
echo
# common downloads table is in another DB
for d in /tmp/phone/browser/apps/com.android.browser/db/*.db; do
    echo "--- schema $d ---"
    sqlite3 "$d" '.schema' 2>&1 | grep -iE "downloads|url|file" | head -5
done