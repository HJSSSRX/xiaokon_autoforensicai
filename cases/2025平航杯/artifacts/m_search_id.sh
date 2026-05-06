#!/bin/bash
# Extract all remaining .bak files (skip already done QQ/wx)
SRC=/tmp/phone/20250415_181118
mkdir -p /tmp/phone/all_bak
for B in "$SRC"/*.bak; do
    NAME=$(basename "$B")
    PKG=$(echo "$NAME" | sed -E 's/.*\(([^)]+)\)\.bak/\1/')
    [ -z "$PKG" ] && continue
    [ "$PKG" = "com.tencent.mobileqq" ] && continue
    [ "$PKG" = "com.tencent.mm" ] && continue
    [ "$PKG" = "com.example.reverseshell2" ] && continue
    [ "$PKG" = "com.android.browser" ] && continue
    OUT="/tmp/phone/all_bak/$PKG"
    [ -d "$OUT" ] && continue
    OFFSET=$(grep -aboP 'apps/' "$B" 2>/dev/null | head -1 | cut -d: -f1)
    [ -z "$OFFSET" ] && continue
    mkdir -p "$OUT"
    dd if="$B" of=/tmp/phone/_t.tar bs=4K iflag=skip_bytes skip=$OFFSET status=none
    tar -C "$OUT" -xf /tmp/phone/_t.tar 2>/dev/null
    rm -f /tmp/phone/_t.tar
done

echo '=== Search for 18-digit Chinese ID card pattern ==='
grep -rIE --include='*.xml' --include='*.db' --include='*.json' --include='*.txt' \
    -aoE '[1-6][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]' \
    /tmp/phone/all_bak /tmp/phone/qq /tmp/phone/wx /tmp/phone/browser 2>/dev/null | sort -u | head -20

echo
echo '=== Search for 15-digit IMEI pattern in xml ==='
grep -rIE --include='*.xml' -aoE 'IMEI["= >:]+[0-9]{15}|imei[":= ]+[0-9]{15}|[^0-9]([0-9]{15})[^0-9]' \
    /tmp/phone/all_bak 2>/dev/null | grep -iE 'imei' | head -20

echo
echo '=== Search WLOGIN_DEVICE_INFO and similar device xml ==='
find /tmp/phone -name 'WLOGIN_DEVICE_INFO.xml' -exec cat {} \;