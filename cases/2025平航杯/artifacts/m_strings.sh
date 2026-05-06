#!/bin/bash
APK=/tmp/phone/trojan/extracted/apps/com.example.reverseshell2/a/base.apk
DEX=/tmp/phone/trojan/apk/classes.dex
JAR=/tmp/phone/trojan/apk/assets/classes0.jar

echo '=== IP:port patterns in apk-extracted files ==='
for f in $DEX $JAR; do
    echo "-- $f --"
    strings -a -n 6 "$f" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}(:[0-9]{1,5})?$|http[s]?://[a-zA-Z0-9.\-/_:?=&%]+' | sort -u | head -15
done

echo '=== Search for IP:port substring in any byte stream ==='
strings -a -n 8 $JAR | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -10

echo '=== Search base.apk dex for typical reverseshell strings ==='
strings -a -n 5 $DEX | grep -iE 'shell|socket|reverse|connect|host|port|camera|takepic|videoRec' | head -30