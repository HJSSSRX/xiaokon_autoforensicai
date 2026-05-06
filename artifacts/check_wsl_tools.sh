#!/bin/bash
for t in strings sqlite3 foremost binwalk fls steghide tcpdump exiftool xxd file chainsaw hayabusa; do
  printf "%-12s " "$t"
  which "$t" 2>/dev/null || echo MISSING
done
