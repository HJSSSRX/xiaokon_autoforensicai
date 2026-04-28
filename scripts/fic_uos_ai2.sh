#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
BASE="/tmp/pc_data/root/.local/share/deepin/uos-ai-assistant"

echo "=== agent ==="
SUDO ls -la $BASE/agent/
echo ""
for f in $(SUDO find $BASE/agent -type f); do
  echo "--- $f ---"
  SUDO cat "$f"
  echo ""
done

echo ""
echo "=== db ==="
SUDO ls -la $BASE/db/
echo ""
mkdir -p /tmp/fic_extract/uos_ai
for f in $(SUDO find $BASE/db -type f); do
  echo "--- $f ---"
  SUDO file "$f"
  base=$(basename "$f")
  SUDO cp "$f" /tmp/fic_extract/uos_ai/
done
SUDO chown -R hjsssr:hjsssr /tmp/fic_extract/uos_ai/
ls -la /tmp/fic_extract/uos_ai/
echo ""
for f in /tmp/fic_extract/uos_ai/*; do
  echo "--- $f ---"
  file "$f"
  if file "$f" | grep -qi sqlite; then
    echo "tables:"
    sqlite3 "$f" ".tables"
    echo ""
    sqlite3 "$f" ".schema" 2>&1 | head -50
    echo ""
    echo "schema dump:"
    for tbl in $(sqlite3 "$f" ".tables"); do
      echo ">>> $tbl"
      sqlite3 -header "$f" "SELECT * FROM $tbl LIMIT 5;" 2>&1
    done
  else
    head -c 1000 "$f"
  fi
done
