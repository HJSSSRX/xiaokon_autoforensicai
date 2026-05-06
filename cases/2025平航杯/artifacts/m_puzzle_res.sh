#!/bin/bash
mkdir -p /tmp/phone/puzzle_apk
cd /tmp/phone/puzzle_apk
unzip -oq "/tmp/phone/20250415_181118/浏览器Download/Puzzle_Game.apk"
echo '=== drawable images ==='
find res -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.bmp' \) | head -40
echo
echo '=== assets / raw ==='
find assets res/raw -type f 2>/dev/null
echo
echo '=== Largest images ==='
find res -type f \( -name '*.png' -o -name '*.jpg' \) -printf '%s %p\n' | sort -rn | head -10