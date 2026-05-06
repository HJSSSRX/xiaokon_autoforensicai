#!/bin/bash
cd /tmp/phone/20250415_181118
echo '=== QQ.bak head ==='
xxd "QQ(com.tencent.mobileqq).bak" | head -8
echo
WX_BAK=$(ls *.bak 2>/dev/null | grep -i tencent.mm)
echo "WX file: [$WX_BAK]"
xxd "$WX_BAK" | head -8
echo
# search "apps/" patterns and ANDROID BACKUP
echo '=== search apps/ pattern in QQ ==='
grep -aboP 'apps/' "QQ(com.tencent.mobileqq).bak" | head -5
echo '=== search ANDROID BACKUP ==='
grep -aboP 'ANDROID BACKUP' "QQ(com.tencent.mobileqq).bak" | head -3
echo '=== search ustar ==='
grep -aboP 'ustar' "QQ(com.tencent.mobileqq).bak" | head -3