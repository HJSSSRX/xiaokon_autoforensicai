#!/bin/bash
echo '=== Extract com.android.mms backup (SMS) ==='
SRC=/tmp/phone/20250415_181118
MMS=$(ls "$SRC"/*.bak | grep com.android.mms)
OFFSET=$(grep -aboP 'apps/' "$MMS" | head -1 | cut -d: -f1)
mkdir -p /tmp/phone/mms
dd if="$MMS" of=/tmp/phone/_t.tar bs=1024 iflag=skip_bytes skip=$OFFSET status=none
tar -C /tmp/phone/mms -xf /tmp/phone/_t.tar 2>&1 | tail -3
rm -f /tmp/phone/_t.tar
find /tmp/phone/mms -type f | head -20
echo
# Also extract com.android.contacts (call log + contacts)
for PKG in com.android.contacts com.android.providers.downloads com.miui.notes com.miui.securitycenter com.example.reverseshell2; do
    BAK=$(ls "$SRC"/*.bak 2>/dev/null | xargs -I{} sh -c 'grep -lE "'$PKG'" "{}" >/dev/null 2>&1 && echo "{}"' | head -1)
done

# extract com.android.contacts directly (multiple files, name unsure due to chinese)
for B in "$SRC"/*.bak; do
    if grep -qaE "apps/com\.android\.contacts/" "$B"; then
        echo "Found contacts in: $B"
    fi
done | head -3

echo
echo '=== mms files & content ==='
find /tmp/phone/mms -type f -exec ls -la {} \;