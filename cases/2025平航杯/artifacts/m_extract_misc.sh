#!/bin/bash
SRC=/tmp/phone/20250415_181118

# Extract bak by exact package name (search header of each .bak)
extract_by_pkg() {
    local PKG="$1"
    local OUT="$2"
    for B in "$SRC"/*.bak; do
        # Read first 200 bytes and check if "com.example.reverseshell2 " or "$PKG " appears
        if head -c 300 "$B" | grep -qaF "$PKG "; then
            local OFFSET=$(grep -aboP 'apps/' "$B" | head -1 | cut -d: -f1)
            echo "[$PKG] -> $(basename "$B"), offset $OFFSET"
            mkdir -p "$OUT"
            dd if="$B" of=/tmp/phone/_t.tar bs=1024 iflag=skip_bytes skip=$OFFSET status=none
            tar -C "$OUT" -xf /tmp/phone/_t.tar 2>&1 | tail -3
            rm -f /tmp/phone/_t.tar
            return 0
        fi
    done
    echo "[$PKG] NOT FOUND"
}

extract_by_pkg "com.android.mms" /tmp/phone/mms
extract_by_pkg "com.miui.notes" /tmp/phone/notes
extract_by_pkg "com.android.contacts" /tmp/phone/contacts
extract_by_pkg "com.miui.securitycenter" /tmp/phone/seccenter
extract_by_pkg "com.xiaomi.jr" /tmp/phone/xmjr

echo
echo '=== mms files ==='
find /tmp/phone/mms -type f 2>/dev/null
echo '=== notes files ==='
find /tmp/phone/notes -type f 2>/dev/null | head -20
echo '=== contacts files ==='
find /tmp/phone/contacts -type f 2>/dev/null | head -20
echo '=== seccenter ==='
find /tmp/phone/seccenter -type f 2>/dev/null
echo '=== xmjr ==='
find /tmp/phone/xmjr -type f 2>/dev/null | head -20