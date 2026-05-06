#!/bin/bash
DEX=/tmp/phone/trojan/extracted/apps/com.example.reverseshell2/r/.cache/classes.dex
APK=/tmp/phone/trojan/extracted/apps/com.example.reverseshell2/a/base.apk
OUT=/tmp/phone/trojan/jadx_out
mkdir -p "$OUT"

# Use jadx on the unpacked classes.dex (post-shell unpack)
file "$DEX"
ls -la "$DEX"

/opt/jadx/bin/jadx -d "$OUT" -r "$DEX" 2>&1 | tail -5
echo '=== generated tree ==='
find "$OUT" -name '*.java' | head -20