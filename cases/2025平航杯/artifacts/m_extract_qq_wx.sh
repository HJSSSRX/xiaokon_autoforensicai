#!/bin/bash
set -e
extract_bak() {
    local BAK="$1"
    local OUT="$2"
    OFFSET=$(grep -aboP '^apps/' "$BAK" | head -1 | cut -d: -f1)
    echo "[$BAK] tar offset: $OFFSET"
    mkdir -p "$OUT"
    cd "$OUT"
    dd if="$BAK" bs=1M skip=0 status=none 2>/dev/null | tail -c +$((OFFSET+1)) | tar xf - 2>&1 | tail -3
    echo "  -> extracted to $OUT"
    du -sh "$OUT" | head -1
}

cd /tmp/phone/20250415_181118

extract_bak "QQ(com.tencent.mobileqq).bak" /tmp/phone/qq
echo
# Find chinese filename for wechat
WX_BAK=$(ls *com.tencent.mm*.bak 2>/dev/null | head -1)
extract_bak "$WX_BAK" /tmp/phone/wx
echo
echo '=== qq tree top ==='
find /tmp/phone/qq -maxdepth 4 -type d | head -30
echo '=== wx tree top ==='
find /tmp/phone/wx -maxdepth 4 -type d | head -30