#!/bin/bash
APK="/tmp/phone/trojan/extracted/apps/com.example.reverseshell2/a/base.apk"
ls -la "$APK"

echo '=== MD5 ==='
md5sum "$APK" | awk '{print toupper($1)}'

echo '=== APK contents top-level ==='
unzip -l "$APK" | head -30

echo '=== lib/ directories (packer fingerprint) ==='
unzip -l "$APK" | grep -E 'lib/|\.so$' | head -20

echo '=== assets ==='
unzip -l "$APK" | grep -i assets | head -10

echo '=== decode AndroidManifest ==='
mkdir -p /tmp/phone/trojan/apk
cd /tmp/phone/trojan/apk
unzip -o "$APK" AndroidManifest.xml resources.arsc assets/* 2>&1 | tail -3

# Try to read AndroidManifest with apktool or aapt
if command -v aapt >/dev/null 2>&1; then
    echo '-- aapt badging --'
    aapt dump badging "$APK" 2>&1 | head -20
elif command -v aapt2 >/dev/null 2>&1; then
    aapt2 dump badging "$APK" 2>&1 | head -20
else
    echo 'no aapt; will install'
fi