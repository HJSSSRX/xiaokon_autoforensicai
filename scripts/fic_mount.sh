#!/usr/bin/env bash
# FIC2026 通用挂载脚本
# Usage:
#   bash fic_mount.sh e01    <file.E01>      [mount_name]
#   bash fic_mount.sh vmdk   <file.vmdk>     [mount_name]
#   bash fic_mount.sh raw    <file.dd>       [mount_name]
#   bash fic_mount.sh vmfs   <vmfs.bin>      [mount_name]
#   bash fic_mount.sh tar    <android.tar>   [extract_dir]
#   bash fic_mount.sh zip    <archive.zip>   [extract_dir]
#   bash fic_mount.sh ls                     # 看当前挂载
#   bash fic_mount.sh umount <name>          # 卸载

set -e
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

CMD="$1"
SRC="$2"
NAME="${3:-mnt}"
BASE="/tmp/fic_$NAME"

case "$CMD" in
  e01)
    [ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }
    SUDO mkdir -p "$BASE/ewf" "$BASE/img"
    SUDO ewfmount "$SRC" "$BASE/ewf"
    echo "[1] EWF mounted at $BASE/ewf/ewf1"
    SUDO mmls "$BASE/ewf/ewf1" || echo "(mmls failed, may be single partition)"
    SUDO losetup -fP --read-only "$BASE/ewf/ewf1"
    LOOP=$(losetup -j "$BASE/ewf/ewf1" | head -1 | cut -d: -f1)
    echo "[2] Loop = $LOOP"
    echo "→ 看 mmls 输出选分区，然后："
    echo "  sudo mount -o ro $LOOP\"p<N>\" $BASE/img"
    ;;
  vmdk)
    [ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }
    SUDO mkdir -p "$BASE"
    SUDO modprobe nbd max_part=16
    SUDO qemu-nbd --read-only --connect=/dev/nbd0 "$SRC"
    echo "[1] VMDK connected to /dev/nbd0"
    SUDO partx -s /dev/nbd0
    echo "→ sudo mount -o ro /dev/nbd0pN $BASE"
    ;;
  raw|dd)
    [ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }
    SUDO mkdir -p "$BASE"
    SUDO mmls "$SRC" || true
    SUDO losetup -fP --read-only "$SRC"
    LOOP=$(losetup -j "$SRC" | head -1 | cut -d: -f1)
    echo "[1] Loop = $LOOP, see partx:"
    SUDO partx -s "$LOOP"
    echo "→ sudo mount -o ro ${LOOP}pN $BASE"
    ;;
  vmfs)
    [ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }
    SUDO mkdir -p "$BASE"
    SUDO vmfs-fuse -o ro "$SRC" "$BASE"
    echo "[1] VMFS mounted at $BASE"
    ls "$BASE"
    ;;
  tar)
    [ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }
    DEST="${3:-/tmp/fic_tar_$NAME}"
    mkdir -p "$DEST"
    tar -xf "$SRC" -C "$DEST"
    echo "[1] Tar extracted to $DEST"
    ls "$DEST" | head
    ;;
  zip|7z)
    [ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }
    DEST="${3:-/tmp/fic_zip_$NAME}"
    mkdir -p "$DEST"
    7z x -y -o"$DEST" "$SRC" | tail -5
    echo "[1] Archive extracted to $DEST"
    ls "$DEST" | head
    ;;
  ls)
    echo "===== Loop devices ====="
    losetup -a
    echo ""
    echo "===== Mounts ====="
    mount | grep -E '/tmp/fic_|/tmp/ewf' || echo "(none)"
    echo ""
    echo "===== NBD ====="
    ls /dev/nbd* 2>/dev/null | head
    ;;
  umount)
    NAME="$2"
    BASE="/tmp/fic_$NAME"
    SUDO umount "$BASE/img" 2>/dev/null || true
    SUDO umount "$BASE/ewf" 2>/dev/null || true
    SUDO umount "$BASE" 2>/dev/null || true
    SUDO losetup -D 2>/dev/null || true
    SUDO qemu-nbd -d /dev/nbd0 2>/dev/null || true
    echo "Done unmounting $NAME"
    ;;
  *)
    echo "Usage: bash fic_mount.sh {e01|vmdk|raw|vmfs|tar|zip|ls|umount} <file> [name]"
    exit 1
    ;;
esac
