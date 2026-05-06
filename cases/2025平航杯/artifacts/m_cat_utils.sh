#!/bin/bash
for f in /tmp/phone/puzzle/sources/com/example/puzzlegame/util/*.java; do
    echo "=== $f ==="
    cat "$f"
    echo
done