#!/bin/bash
echo '=== Search for IMEI strings in extracted backups ==='
grep -rIE -ai 'imei|IMEI' /tmp/phone/all_bak /tmp/phone/qq /tmp/phone/wx /tmp/phone/browser 2>/dev/null \
  | grep -v 'meiyou\|imeiyou\|emit\|mImei\|imeil\|gimei' \
  | grep -E '[0-9]{14,16}' | head -30
echo
echo '=== bd_setting / com.baidu.input_mi context for the ID ==='
grep -B2 -A2 -F '310104200108110624' /tmp/phone/all_bak/com.baidu.input_mi/apps/com.baidu.input_mi/sp/com.baidu.input_mi_preferences.xml | head -30
echo
echo '=== xiaomi market / passport device id ==='
find /tmp/phone/all_bak -name '*device*' -o -name '*Passport*' -o -name '*account*' 2>/dev/null | head -10
echo
echo '=== look for 14-15 digit IMEI in sp/xml under settings/securitycenter/market ==='
for d in /tmp/phone/all_bak/com.miui.securitycenter /tmp/phone/all_bak/com.android.settings /tmp/phone/all_bak/com.xiaomi.market /tmp/phone/all_bak/com.xiaomi.jr; do
    if [ -d "$d" ]; then
        echo "-- $d --"
        grep -rIE 'imei|deviceId' "$d" 2>/dev/null | head -10
    fi
done