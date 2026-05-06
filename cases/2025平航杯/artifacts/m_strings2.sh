#!/bin/bash
mkdir -p /tmp/phone/trojan/apk_full
cd /tmp/phone/trojan/apk_full
unzip -oq /tmp/phone/trojan/extracted/apps/com.example.reverseshell2/a/base.apk
ls *.dex
echo '=== IP/URL in dex ==='
strings -a classes.dex | grep -E "^([0-9]{1,3}[.]){3}[0-9]{1,3}|^http" | sort -u | head -20
echo '=== reverseshell-related strings ==='
strings -a classes.dex | grep -iE "shell|socket|reverse|host|port|camera|takepic|video" | sort -u | head -30
echo '=== IP/URL in classes0.jar ==='
strings -a assets/classes0.jar | grep -E "^([0-9]{1,3}[.]){3}[0-9]{1,3}|^http" | sort -u | head -20