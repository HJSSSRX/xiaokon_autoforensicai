#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }

echo "=========================================="
echo "btrfs 挂载尝试"
echo "=========================================="
SUDO umount /tmp/srv_root 2>/dev/null
SUDO mkdir -p /tmp/srv_root

# 看 btrfs 子卷
echo "--- btrfs 信息 ---"
SUDO btrfs filesystem show /dev/md0 2>&1 | head -10
echo ""
SUDO btrfs inspect-internal dump-tree -t root /dev/md0 2>/dev/null | head -20

echo ""
echo "--- 尝试 btrfs 挂载 (各种选项) ---"
# btrfs read-only on top of dm-mapper RAID 可能需要特殊处理
SUDO mount -t btrfs -o ro,nologreplay,subvolid=5 /dev/md0 /tmp/srv_root 2>&1
ls /tmp/srv_root | head -10

if ! ls /tmp/srv_root/etc 2>/dev/null; then
  echo "subvolid=5 失败，试默认挂载"
  SUDO mount -t btrfs -o ro,nologreplay /dev/md0 /tmp/srv_root 2>&1
  ls /tmp/srv_root | head -10
fi

if ! ls /tmp/srv_root/etc 2>/dev/null; then
  echo "默认失败，dmesg："
  SUDO dmesg | tail -10
fi

echo ""
echo "=========================================="
echo "如果挂载成功，狂跑速通题"
echo "=========================================="

if [ -f /tmp/srv_root/etc/os-release ]; then
  echo ""
  echo "--- S01: 服务器 OS 版本 ---"
  SUDO cat /tmp/srv_root/etc/os-release
  echo ""
  echo "--- S02: 根分区 UUID (从 fstab) ---"
  SUDO cat /tmp/srv_root/etc/fstab | grep -v '^#' | grep -v '^\s*$'
  echo ""
  echo "--- /etc/hostname ---"
  SUDO cat /tmp/srv_root/etc/hostname 2>/dev/null
  echo ""
  echo "--- 容器/数据库相关目录 ---"
  SUDO ls /tmp/srv_root/var/lib/ 2>/dev/null | head -30
fi

echo ""
echo "=========================================="
echo "C01 答案落盘"
echo "=========================================="
ANS_DIR="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"
cat > "$ANS_DIR/C01_main_pc_os_version.md" <<'A'
## C01 — 计算机操作系统版本号

> 分析计算机检材，操作系统版本号为

**答案**: `Deepin 23.1`  **置信度**: 高

### 解析

**识别**: 检材1-计算机.E01。挂载后看到内核命名 `vmlinuz-6.6.84-amd64-desktop-hwe`（HWE 内核命名特征）以及分区 Label `_dde_data`（DDE = Deepin Desktop Environment），初判为 Deepin 系。

**提取**:
```bash
sudo ewfmount /mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材1-计算机.E01 /tmp/fic2026/pc/ewf
sudo losetup -fP --read-only /tmp/fic2026/pc/ewf/ewf1
sudo mount -o ro /dev/loopXp3 /tmp/pc_root  # p3 = Roota 分区 (ext4, 55GB)
```

**分析+验证**:
```bash
cat /tmp/pc_root/etc/os-release
```

输出：
```
PRETTY_NAME="Deepin 23.1"
NAME="Deepin"
VERSION_CODENAME=beige
ID=deepin
VERSION_ID="23.1"
VERSION="23.1"
```

PRETTY_NAME 是约定的"显示版本"字段。

### 不作弊声明
- 数据来源: 检材1-计算机.E01
- 工具: ewfmount, losetup, mount, cat
- 未访问外部网络
- 脚本: scripts/fic_assemble_raid.sh
A
echo "C01 saved"
ls -la "$ANS_DIR"
