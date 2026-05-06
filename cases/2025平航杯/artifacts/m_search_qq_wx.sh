#!/bin/bash
echo '=== Search for reverseshell2 mentions across all extracted ==='
grep -rIl 'reverseshell2\|reverseShell\|ReverseShell' /tmp/phone/qq /tmp/phone/wx 2>/dev/null | head -10

echo '=== Search for any HTTP URL referencing apk download ==='
grep -aroIE 'https?://[a-zA-Z0-9.\-]+/[a-zA-Z0-9._\-/?=&%~]*\.apk' /tmp/phone/qq /tmp/phone/wx 2>/dev/null | head -20

echo '=== List all .db / .sqlite / .json / .xml in QQ ==='
find /tmp/phone/qq -type f \( -name '*.db' -o -name '*.sqlite' -o -name '*.xml' -o -name '*.json' \) 2>/dev/null | head -20

echo '=== Find apk attachments / files in QQ ==='
find /tmp/phone/qq -type f -iname '*.apk' 2>/dev/null
find /tmp/phone/wx -type f -iname '*.apk' 2>/dev/null

echo '=== Find puzzle game ==='
find /tmp/phone -iname '*puzzle*' 2>/dev/null

echo '=== QQ profile / mobileqq.db ==='
ls /tmp/phone/qq/apps/com.tencent.mobileqq/db/ 2>/dev/null | head -20

echo '=== sp xml files (QQ) ==='
ls /tmp/phone/qq/apps/com.tencent.mobileqq/sp/ 2>/dev/null | head -20