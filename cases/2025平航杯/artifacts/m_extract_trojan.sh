#!/bin/bash
set -e
BAK="/tmp/phone/20250415_181118/Google Service Framework(com.example.reverseshell2).bak"
WORK=/tmp/phone/trojan
mkdir -p "$WORK"
cd "$WORK"

# Find tar data start: "apps/" pattern
OFFSET=$(grep -aboP '^apps/' "$BAK" | head -1 | cut -d: -f1)
echo "tar data offset: $OFFSET"

# Extract tar
dd if="$BAK" of=trojan.tar bs=1 skip="$OFFSET" status=none
ls -la trojan.tar

# List tar contents
echo '=== tar contents ==='
tar tf trojan.tar 2>&1 | head -20

# Extract all
mkdir -p extracted && cd extracted
tar xf ../trojan.tar 2>&1 | tail -5
echo '=== extracted tree ==='
find . -type f | head -30