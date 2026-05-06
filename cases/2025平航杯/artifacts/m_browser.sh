#!/bin/bash
SRC=/tmp/phone/20250415_181118
BAK="$SRC/浏览器(com.android.browser).bak"
ls -la "$BAK"
OFFSET=$(grep -aboP 'apps/' "$BAK" | head -1 | cut -d: -f1)
echo "tar offset: $OFFSET"
mkdir -p /tmp/phone/browser
dd if="$BAK" of=/tmp/phone/_t.tar bs=1024 iflag=skip_bytes skip=$OFFSET status=none
tar -C /tmp/phone/browser -xf /tmp/phone/_t.tar 2>&1 | tail -3
rm /tmp/phone/_t.tar
echo
echo '=== browser tree ==='
find /tmp/phone/browser -type f | head -30
echo
echo '=== databases ==='
find /tmp/phone/browser -name '*.db' -exec ls -la {} \;