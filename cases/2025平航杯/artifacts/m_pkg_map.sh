#!/bin/bash
SRC=/tmp/phone/20250415_181118

echo '=== Build pkg → file mapping ==='
for B in "$SRC"/*.bak; do
    PKG=$(head -c 200 "$B" | tr -d '\0' | sed -n 's/^MIUI BACKUP.*[0-9]\+.*\(com\.[a-zA-Z._0-9]*\) .*/\1/p' | head -1)
    [ -z "$PKG" ] && PKG=$(head -c 200 "$B" | strings -n 6 | grep -E '^com\.[a-z0-9_.]+$' | head -1)
    echo "$(basename "$B")|$PKG"
done | head -40