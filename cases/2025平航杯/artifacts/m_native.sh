#!/bin/bash
# Look in native libs
mkdir -p /tmp/phone/trojan/apk
cd /tmp/phone/trojan/apk
unzip -oq /tmp/phone/trojan/extracted/apps/com.example.reverseshell2/a/base.apk
echo '=== libs ==='
find lib -type f
echo
for so in lib/*/*.so; do
    echo "=== strings $so ==="
    strings -a -n 5 "$so" | grep -aoE '([0-9]{1,3}\.){3}[0-9]{1,3}(:[0-9]{1,5})?|:[0-9]{2,5}\b|http[s]?://[a-zA-Z0-9.\-]+' | sort -u | head -30
done
echo
echo '=== Search all strings in classes0.jar (encrypted) ==='
strings -a assets/classes0.jar | grep -aoE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u | head -10
echo
echo '=== AndroidManifest network info ==='
aapt dump xmltree /tmp/phone/trojan/extracted/apps/com.example.reverseshell2/a/base.apk AndroidManifest.xml 2>&1 | grep -iE 'permission|service name|action' | head -20