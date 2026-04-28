#!/usr/bin/env bash
# 一次性跑多道速通题
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "=========================================="
echo "B01: SampleVC.exe 的 MD5"
echo "=========================================="
USB_IMG="/tmp/fic2026/usb/ewf/ewf1"
# fls 拿到 SampleVC.exe inode
SAMPLE_INODE=$(SUDO fls "$USB_IMG" 2>/dev/null | grep -i 'SampleVC.exe' | head -1 | awk '{print $2}' | tr -d ':')
echo "SampleVC.exe inode: $SAMPLE_INODE"
mkdir -p /tmp/fic_extract
SUDO icat "$USB_IMG" "$SAMPLE_INODE" > /tmp/fic_extract/SampleVC.exe 2>/dev/null
ls -la /tmp/fic_extract/SampleVC.exe
md5sum /tmp/fic_extract/SampleVC.exe
echo ""

echo "=========================================="
echo "B02: SampleVC.exe 编译日期 (PE TimeDateStamp)"
echo "=========================================="
# 用 python 读 PE 头
python3 - <<'PY'
import struct, datetime
with open("/tmp/fic_extract/SampleVC.exe", "rb") as f:
    data = f.read()
e_lfanew = struct.unpack_from("<I", data, 0x3C)[0]
sig = data[e_lfanew:e_lfanew+4]
print(f"PE signature: {sig}")
# COFF header at e_lfanew+4
# TimeDateStamp at offset 4 within COFF (so e_lfanew+8)
ts = struct.unpack_from("<I", data, e_lfanew+8)[0]
print(f"TimeDateStamp (raw): {ts} (0x{ts:08x})")
print(f"UTC: {datetime.datetime.utcfromtimestamp(ts).isoformat()} UTC")
print(f"Beijing: {(datetime.datetime.utcfromtimestamp(ts) + datetime.timedelta(hours=8)).isoformat()} +08:00")
PY
echo ""

echo "=========================================="
echo "U盘里被加密的文件预览（B04, B05 用）"
echo "=========================================="
SUDO fls "$USB_IMG" 2>/dev/null | head -20
echo "(看是否还有其他文件)"
echo ""

echo "=========================================="
echo "C01: 计算机 OS 版本（Linux 桌面）"
echo "=========================================="
PC_IMG="/tmp/fic2026/pc/ewf/ewf1"
# root 分区 offset 19666944
echo "找 /etc/os-release..."
ETC_INODE=$(SUDO fls -o 19666944 "$PC_IMG" 2>/dev/null | awk '$3=="etc" {print $2}' | tr -d ':' | head -1)
echo "etc inode: $ETC_INODE"
if [ -z "$ETC_INODE" ]; then
  # 试另一种格式
  ETC_INODE=$(SUDO fls -o 19666944 "$PC_IMG" 2>/dev/null | grep -E '\setc$' | head -1 | awk '{print $2}' | tr -d ':')
  echo "  retry etc inode: $ETC_INODE"
fi
if [ -n "$ETC_INODE" ]; then
  OSREL=$(SUDO fls -o 19666944 "$PC_IMG" "$ETC_INODE" 2>/dev/null | grep 'os-release' | head -1 | awk '{print $2}' | tr -d ':')
  echo "os-release inode: $OSREL"
  if [ -n "$OSREL" ]; then
    echo "--- /etc/os-release ---"
    SUDO icat -o 19666944 "$PC_IMG" "$OSREL"
    echo "------"
  fi
fi
echo ""

echo "=========================================="
echo "S01/S02: 服务器 OS 版本 + 根分区 UUID"
echo "=========================================="
# 先尝试挂载 LVM 根卷 /dev/volum/root（系统盘）
mkdir -p /tmp/srv_root
SUDO mount -o ro /dev/volum/root /tmp/srv_root 2>&1
echo "挂载结果："
SUDO ls -la /tmp/srv_root | head -10
echo ""
echo "--- /etc/os-release ---"
SUDO cat /tmp/srv_root/etc/os-release 2>/dev/null
echo ""
echo "--- /etc/fstab (拿根分区 UUID) ---"
SUDO cat /tmp/srv_root/etc/fstab 2>/dev/null
echo ""
echo "--- blkid /dev/volum/root 看 UUID ---"
SUDO blkid /dev/volum/root /dev/root/data 2>/dev/null
echo ""
echo "--- lsblk ---"
SUDO lsblk -f /dev/loop3 /dev/loop4 2>/dev/null | head -20
