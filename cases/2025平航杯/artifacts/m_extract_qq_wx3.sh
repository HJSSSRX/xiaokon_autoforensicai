#!/bin/bash
extract_bak() {
    local BAK="$1"
    local OUT="$2"
    OFFSET=$(grep -aboP '^apps/' "$BAK" | head -1 | cut -d: -f1)
    echo "[$(basename $BAK)] tar offset: $OFFSET, size $(stat -c%s "$BAK")"
    mkdir -p "$OUT"
    dd if="$BAK" of=/tmp/phone/_t.tar bs=64K iflag=skip_bytes skip=$OFFSET status=none
    tar -C "$OUT" -xf /tmp/phone/_t.tar 2>&1 | tail -3
    rm -f /tmp/phone/_t.tar
    du -sh "$OUT"
}

SRC=/tmp/phone/20250415_181118
extract_bak "$SRC/QQ(com.tencent.mobileqq).bak" /tmp/phone/qq
WX_BAK=$(ls $SRC/*.bak 2>/dev/null | grep -F com.tencent.mm | head -1)
extract_bak "$WX_BAK" /tmp/phone/wx

echo '=== qq tree (depth 4) ==='
find /tmp/phone/qq -maxdepth 4 -type d 2>/dev/null | head -40
echo '=== wx tree (depth 4) ==='
find /tmp/phone/wx -maxdepth 4 -type d 2>/dev/null | head -40