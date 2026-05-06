#!/bin/bash
for t in binwalk foremost fls strings sqlite3 exiftool xxd file steghide; do
  printf "%-12s " "$t"
  v=$("$t" --version 2>/dev/null | head -1)
  if [ -z "$v" ]; then v=$("$t" -V 2>/dev/null | head -1); fi
  if [ -z "$v" ]; then v=$(which "$t"); fi
  echo "$v"
done
