#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "===== 验证 ewf1 存在并跑 mmls ====="
for tag in pc srv usb; do
  echo ""
  echo "--- $tag ---"
  SUDO ls -la /tmp/fic2026/$tag/ewf/ 2>&1 | head -5
  IMG="/tmp/fic2026/$tag/ewf/ewf1"
  if SUDO test -f "$IMG"; then
    SUDO file "$IMG" 2>/dev/null | head -1
    SUDO mmls "$IMG" 2>&1 | head -15
  fi
done

echo ""
echo "===== fls 看根目录 ====="
for tag in pc srv usb; do
  IMG="/tmp/fic2026/$tag/ewf/ewf1"
  echo ""
  echo "--- $tag (尝试每个分区的根目录) ---"
  # 拿到所有分区起始 sector
  PARTS=$(SUDO mmls "$IMG" 2>/dev/null | awk '/^[0-9]+:/ && $4 ~ /^[0-9]+$/ {print $3}' | head -5)
  if [ -z "$PARTS" ]; then
    SUDO fls "$IMG" 2>/dev/null | head -10
  else
    for off in $PARTS; do
      echo "  分区 offset=$off:"
      SUDO fls -o "$off" "$IMG" 2>/dev/null | head -8
    done
  fi
done
