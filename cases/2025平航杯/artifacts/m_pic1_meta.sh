#!/bin/bash
strings /tmp/phone/puzzle_apk/resources.arsc 2>/dev/null | grep -aE 'university|college|school|hangzhou|大学|学院|杭州|毕昇|沈括' | head -20
echo '--'
# Look at all string resources
aapt dump strings /tmp/phone/20250415_181118/浏览器Download/Puzzle_Game.apk 2>/dev/null | grep -aE '大学|学院|university|college|hangzhou' | head -20
echo '--'
echo 'pic1 EXIF/comment scan'
exiftool -Comment -ImageDescription -UserComment /tmp/phone/puzzle_apk/res/drawable-hdpi-v4/pic1.jpg