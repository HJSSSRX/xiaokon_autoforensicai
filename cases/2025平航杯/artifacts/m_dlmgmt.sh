#!/bin/bash
DB=/tmp/phone/browser/apps/com.android.browser/db/browser2.db
echo '=== downloadmanagement schema ==='
sqlite3 "$DB" '.schema downloadmanagement'
echo
echo '=== downloadmanagement rows ==='
sqlite3 -header -column "$DB" 'SELECT * FROM downloadmanagement;' 2>&1 | head -30