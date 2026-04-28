#!/usr/bin/env bash
# Deepin-mail database analysis for C03 (gold) and C08 (ransom)

DB="/tmp/pc_data/home/lha/.local/share/deepin/deepin-mail/mail/db/deepin_mail.V.2.0.db"
OUT="/tmp/fic_extract/mail_dig.log"

exec > >(tee -a "$OUT") 2>&1

echo "========================================"
echo "File info"
echo "========================================"
ls -lh "$DB"
file "$DB"

echo ""
echo "========================================"
echo "Hex header"
echo "========================================"
xxd "$DB" | head -5

echo ""
echo "========================================"
echo "SQLite tables"
echo "========================================"
sqlite3 "$DB" ".tables" 2>&1

echo ""
echo "========================================"
echo "Full schema"
echo "========================================"
sqlite3 "$DB" ".schema" 2>&1 | head -80

echo ""
echo "========================================"
echo "String search: gold / 黄金"
echo "========================================"
strings "$DB" | grep -iE "gold|huangjin|jintiao|jindian" | head -30

echo ""
echo "========================================"
echo "String search: ransom / 勒索 / decrypt"
echo "========================================"
strings "$DB" | grep -iE "ransom|leisuo|decrypt|jiaomi|huifu|contact" | head -30

echo ""
echo "========================================"
echo "String search: email / subject / from"
echo "========================================"
strings "$DB" | grep -iE "subject|from:|to:|@" | head -30

echo ""
echo "Done. Output: $OUT"
