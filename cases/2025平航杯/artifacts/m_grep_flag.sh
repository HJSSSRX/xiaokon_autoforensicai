#!/bin/bash
grep -rIn -E 'flag|FLAG|secret|Egg' /tmp/phone/puzzle/sources/com/example/puzzlegame/ | head -40
echo
echo '=== PuzzleMain.java relevant parts ==='
grep -n -E 'flag|Flag|FLAG|isSuccess|congrats|onComplete' /tmp/phone/puzzle/sources/com/example/puzzlegame/activity/PuzzleMain.java
echo
echo '=== MainActivity ==='
cat /tmp/phone/puzzle/sources/com/example/puzzlegame/activity/MainActivity.java | head -80