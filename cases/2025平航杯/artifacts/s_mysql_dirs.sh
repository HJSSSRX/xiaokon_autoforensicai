#!/bin/bash
S=/mnt/server
echo '=== data subdirs ==='
sudo ls -la $S/www/server/data/ 2>&1 | head -30
echo
echo '=== each db file count ==='
for d in $S/www/server/data/*/; do
    cnt=$(sudo ls "$d" 2>/dev/null | wc -l)
    echo "$cnt files: $d"
done
echo
echo '=== look for tp_admin ibd ==='
sudo find $S/www/server/data -name 'tp_admin*' 2>/dev/null | head
sudo find $S/www/server/data -name 'tp_config*' 2>/dev/null | head
sudo find $S/www/server/data -name 'tp_order*' 2>/dev/null | head