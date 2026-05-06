#!/bin/bash
echo '=== all pic / image files ==='
find /tmp/phone/puzzle_apk -type f -iname '*pic*' -o -iname '*flag*' -o -iname '*secret*' 2>/dev/null
echo
echo '=== all jpg/png in res (non-system) ==='
find /tmp/phone/puzzle_apk/res -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) | grep -v 'abc_\|notification\|ic_launcher\|design_\|tooltip\|btn_' | head -20
echo
echo '=== anything in classes (multiple dex) ==='
ls /tmp/phone/puzzle_apk/*.dex
echo
echo '=== AndroidManifest ==='
which aapt && aapt dump xmltree /tmp/phone/20250415_181118/浏览器Download/Puzzle_Game.apk AndroidManifest.xml 2>&1 | grep -iE 'flag|activity name=|action android:name="android.intent.action' | head -20