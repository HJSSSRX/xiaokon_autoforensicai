#!/bin/bash
D=/tmp/phone/trojan/extracted/apps/com.example.reverseshell2/r/.cache
ls -la "$D"
echo
for f in "$D"/*; do
    echo "=== $f ==="
    file "$f"
    head -c 32 "$f" | xxd
done