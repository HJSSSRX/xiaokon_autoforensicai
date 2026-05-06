#!/bin/bash
extract_bak() {
    local BAK="$1"
    local OUT="$2"
    OFFSET=$(grep -aboP '^apps/' "$BAK" | head -1 | cut -d: -f1)
    echo "[$BAK] tar offset: $OFFSET, size $(stat -c%s "$BAK")"
    mkdir -p "$OUT"
    cd "$OUT"
    # Use dd with bs trick: read from offset to EOF
    dd if="$BAK" of=/tmp/phone/_t.tar bs=64K iflag=skip_bytes skip=$OFFSET status=none
    tar xf /tmp/phone/_t.tar 2>&1 | tail -3
    rm -f /tmp/phone/_t.tar
    du -sh "$OUT"
}

cd /tmp/phone/20250415_181118
extract_bak "QQ(com.tencent.mobileqq).bak" /tmp/phone/qq
WX_BAK=$(ls *.bak 2>/dev/null | grep -F com.tencent.mm | head -1)
extract_bak "$WX_BAK" /tmp/phone/wx

echo '=== qq tree (depth 4) ==='
find /tmp/phone/qq -maxdepth 4 -type d 2>/dev/null | head -30
echo '=== wx tree (depth 4) ==='
find /tmp/phone/wx -maxdepth 4 -type d 2>/dev/null | head -30