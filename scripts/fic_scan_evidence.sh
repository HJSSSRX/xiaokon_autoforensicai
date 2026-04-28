#!/usr/bin/env bash
# FIC2026 检材一键扫描
# Usage: bash fic_scan_evidence.sh <检材目录>
# Default: /mnt/e/fffff-TEMP/2026FIC/2026FIC_20260425112747Q

DIR="${1:-/mnt/e/fffff-TEMP/2026FIC/2026FIC_20260425112747Q}"

if [ ! -d "$DIR" ]; then
  echo "[ERR] 目录不存在: $DIR"
  echo "Usage: bash fic_scan_evidence.sh <dir>"
  exit 1
fi

echo "===== 检材目录: $DIR ====="
echo ""

echo "[1] 文件清单（前 50 大）"
echo "----------------------------------------"
find "$DIR" -type f -printf "%s\t%p\n" 2>/dev/null | sort -rn | head -50 | numfmt --field=1 --to=iec --suffix=B 2>/dev/null

echo ""
echo "[2] 文件类型识别"
echo "----------------------------------------"
find "$DIR" -type f 2>/dev/null | while read f; do
  size=$(stat -c%s "$f" 2>/dev/null)
  # 只对 > 1MB 的做 file 识别
  if [ "$size" -gt 1048576 ] 2>/dev/null; then
    type=$(file -b "$f" | head -c 80)
    echo "$(numfmt --to=iec --suffix=B $size 2>/dev/null)  | $type  | ${f#$DIR/}"
  fi
done | head -50

echo ""
echo "[3] 按扩展名分类"
echo "----------------------------------------"
find "$DIR" -type f 2>/dev/null | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -rn | head -20

echo ""
echo "[4] 总览"
echo "----------------------------------------"
total_size=$(du -sb "$DIR" 2>/dev/null | cut -f1)
total_count=$(find "$DIR" -type f 2>/dev/null | wc -l)
echo "总文件数: $total_count"
echo "总大小  : $(numfmt --to=iec --suffix=B $total_size 2>/dev/null)"

echo ""
echo "[5] 关键检材类型推断"
echo "----------------------------------------"
for kw in "E01" "vmdk" "vmem" "raw" "dd" "img" "pcap" "pcapng" "tar" "zip" "7z" "rar" "ova" "ovf" "vmsn" "vmss"; do
  cnt=$(find "$DIR" -type f -iname "*.$kw" 2>/dev/null | wc -l)
  [ "$cnt" -gt 0 ] && echo "  *.$kw : $cnt 个"
done
