#!/usr/bin/env bash
# FIC2026 检材预挂载（只看结构不读内容）
set +e
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

BASE="/mnt/e/ffffff-JIANCAI/2026FIC团体赛"
FACTS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/facts.md"
MNT="/tmp/fic2026"

mkdir -p "$MNT"

# 清理旧挂载
SUDO umount "$MNT"/*/img 2>/dev/null
SUDO umount "$MNT"/*/ewf 2>/dev/null
SUDO losetup -D 2>/dev/null
sleep 1

echo "===== [1] 检材1-计算机（PC 镜像）=====" | tee -a /tmp/fic_preparse.log
mkdir -p "$MNT/pc/ewf"
SUDO ewfmount "$BASE/检材1-计算机.E01" "$MNT/pc/ewf" 2>&1 | tail -3
if [ -f "$MNT/pc/ewf/ewf1" ]; then
  echo "[OK] PC 镜像已挂为 $MNT/pc/ewf/ewf1"
  SUDO mmls "$MNT/pc/ewf/ewf1" 2>&1 | head -20
else
  echo "[FAIL] PC ewfmount"
fi

echo ""
echo "===== [2] 检材3-服务器（两个 E01 合并）====="
mkdir -p "$MNT/srv/ewf"
# E01 分段，ewfmount 只需给第一个
SUDO ewfmount "$BASE/检材3-服务器/检材3-1.E01" "$MNT/srv/ewf" 2>&1 | tail -3
if [ -f "$MNT/srv/ewf/ewf1" ]; then
  SIZE=$(stat -c%s "$MNT/srv/ewf/ewf1")
  echo "[OK] 服务器合并镜像 $(numfmt --to=iec --suffix=B $SIZE) @ $MNT/srv/ewf/ewf1"
  SUDO mmls "$MNT/srv/ewf/ewf1" 2>&1 | head -20
else
  echo "[FAIL] 服务器 ewfmount"
fi

echo ""
echo "===== [3] 检材4-U盘 ====="
mkdir -p "$MNT/usb/ewf"
SUDO ewfmount "$BASE/检材4-U盘.E01" "$MNT/usb/ewf" 2>&1 | tail -3
if [ -f "$MNT/usb/ewf/ewf1" ]; then
  echo "[OK] U盘镜像 @ $MNT/usb/ewf/ewf1"
  SUDO mmls "$MNT/usb/ewf/ewf1" 2>&1 | head -10 || echo "(可能单分区 FAT/exFAT)"
  file "$MNT/usb/ewf/ewf1" | head -1
else
  echo "[FAIL] U盘 ewfmount"
fi

echo ""
echo "===== [4] 检材2-手机（tar 解压到 /tmp/phone_extract 由 PHONE 窗口处理） ====="
echo "tar 大小：$(ls -lh $BASE/检材2-手机.tar | awk '{print \$5}')"
echo "预览 tar 根目录："
tar -tf "$BASE/检材2-手机.tar" 2>/dev/null | head -20
echo ""
echo "tar 内条目总数（可能慢）..."
TAR_COUNT=$(tar -tf "$BASE/检材2-手机.tar" 2>/dev/null | wc -l)
echo "总条目: $TAR_COUNT"

echo ""
echo "===== 预挂载完成 ====="
echo "MAIN 要用的："
echo "  PC 镜像:    $MNT/pc/ewf/ewf1"
echo "  服务器:     $MNT/srv/ewf/ewf1"
echo "  U盘:        $MNT/usb/ewf/ewf1"
echo ""
echo "PHONE 要用的："
echo "  手机 tar:   $BASE/检材2-手机.tar（需 PHONE 窗口解压到 /tmp/phone_extract）"
