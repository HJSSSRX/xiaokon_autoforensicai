#!/bin/bash
echo '=== files containing string "imei" ==='
grep -rIli 'imei' /tmp/phone/all_bak 2>/dev/null | head -30
echo
echo '=== Each: extract imei + 15-digit ==='
for f in $(grep -rIli 'imei' /tmp/phone/all_bak 2>/dev/null); do
    HIT=$(grep -aoE '"?[Ii]mei"?\s*[":=]\s*"?[0-9]{14,16}"?' "$f" 2>/dev/null | head -3)
    if [ -n "$HIT" ]; then
        echo "FILE: $f"
        echo "$HIT"
        echo
    fi
done | head -60
echo
echo '=== Generic 15-digit context near imei ==='
grep -aroE '[Ii][Mm][Ee][Ii][^0-9]{0,30}[0-9]{14,16}' /tmp/phone/all_bak 2>/dev/null | head -20