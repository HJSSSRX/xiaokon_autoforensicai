#!/bin/bash
DIR="/tmp/phone/20250415_181118/浏览器Download"
echo '=== qidm content ==='
cat "$DIR/qidm"
echo
echo
echo '=== qidm hex ==='
xxd "$DIR/qidm"
echo
echo '=== fix2_sign.apk md5 (vs trojan) ==='
md5sum "$DIR/fix2_sign.apk"
md5sum "/tmp/phone/trojan/extracted/apps/com.example.reverseshell2/a/base.apk"
echo
echo '=== Puzzle_Game.apk info ==='
aapt dump badging "$DIR/Puzzle_Game.apk" 2>&1 | head -10