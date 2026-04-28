#!/usr/bin/env bash
ANS_DIR="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"

cat > "$ANS_DIR/S01_main_srv_os_version.md" <<'A'
## S01 — 服务器主机操作系统版本

> 该服务器主机操作系统版本为

**答案**: `Debian GNU/Linux 13 (trixie)` 或 `Debian 13`  **置信度**: 高

### 解析

**识别**: 检材3-服务器是双 E01 拼成的 LVM + RAID0 + btrfs 架构。

**提取**:
```bash
# 挂载两个 E01
sudo ewfmount 检材3-1.E01 /tmp/fic2026/srv/ewf
sudo ewfmount 检材3-2.E01 /tmp/fic2026/srv2/ewf
sudo losetup -fP --read-only /tmp/fic2026/srv/ewf/ewf1
sudo losetup -fP --read-only /tmp/fic2026/srv2/ewf/ewf1
# 激活 LVM
sudo vgchange -ay   # 激活 root 和 volum 两个 VG
# 组装 RAID0
sudo mdadm --assemble --readonly /dev/md0 /dev/volum/root /dev/root/data
# 挂载 btrfs（注意 nologreplay 只读保护）
sudo mount -t btrfs -o ro,nologreplay /dev/md0 /tmp/srv_root
```

**分析+验证**:
```bash
sudo cat /tmp/srv_root/@rootfs/etc/os-release
```

输出关键字段：
```
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
ID=debian
```

注：hostname 显示为 `ubuntu`（误导命名），但 os-release 明确为 Debian 13。

### 不作弊声明
- 数据来源: 检材3-1.E01 + 检材3-2.E01
- 工具: ewfmount, losetup, vgchange, mdadm, mount, cat
- 未访问外部网络
- 脚本: scripts/fic_assemble_raid.sh + scripts/fic_mount_btrfs.sh
A

cat > "$ANS_DIR/S02_main_srv_root_uuid.md" <<'A'
## S02 — 服务器根分区硬盘的 UUID 号

> 该服务器根分区硬盘的uuid号为

**答案**: `3231e52f-5e15-44c4-b224-e29cb4201c0e`  **置信度**: 高

### 解析

**识别**: 服务器根分区使用 btrfs 文件系统（subvol=@rootfs），其文件系统 UUID 即根分区 UUID。

**提取+分析**:
```bash
# 方法1: blkid 直接看 btrfs UUID
sudo blkid /dev/md0
# 输出: /dev/md0: UUID="3231e52f-5e15-44c4-b224-e29cb4201c0e" ... TYPE="btrfs"

# 方法2: /etc/fstab 互证
sudo cat /tmp/srv_root/@rootfs/etc/fstab
# UUID=3231e52f-5e15-44c4-b224-e29cb4201c0e / btrfs defaults,subvol=@rootfs 0 0
```

两个数据源完全一致：根分区 UUID = `3231e52f-5e15-44c4-b224-e29cb4201c0e`。

### 不作弊声明
- 数据来源: 检材3-1.E01 + 检材3-2.E01（拼装后的 /dev/md0）
- 工具: blkid, cat
- 脚本: scripts/fic_srv_speed.sh
A

cat > "$ANS_DIR/S04_main_srv_snapshot.md" <<'A'
## S04 — 服务器根分区快照路径

> 该服务器根分区快照路径为

**答案**: `/root/history` （btrfs subvolume，相对于根挂载点）  **置信度**: 高

### 解析

**识别**: btrfs 文件系统支持子卷（subvolume）/快照（snapshot）。@rootfs 是主子卷，下属若干快照存于其内。

**提取+分析**:
```bash
sudo btrfs subvolume list /tmp/srv_root
```

输出：
```
ID 256 gen 4389 top level 5 path @rootfs
ID 257 gen 4377 top level 256 path @rootfs/root/history
```

ID 257 是 ID 256 (@rootfs) 的子级，路径 `@rootfs/root/history`。
- 在主子卷 @rootfs 视角下，路径是 `/root/history`
- 这就是根分区下用户层面可见的快照位置

### 不作弊声明
- 数据来源: 检材3 拼装后的 btrfs (/dev/md0)
- 工具: btrfs-progs (btrfs subvolume list)
- 脚本: scripts/fic_srv_deep.sh
A

cat > "$ANS_DIR/S12_main_srv_db_container_tech.md" <<'A'
## S12 — 该网站数据库使用了哪一类容器技术

> 该网站数据库使用了哪一类容器技术

**答案**: `LXC`（Linux Containers）  **置信度**: 高

### 解析

**识别**: 服务器同时安装了 docker、containerd、lxc、lxd 多种容器栈，需确认实际承载数据库的是哪一种。

**提取+分析**:
```bash
# Docker imagedb 实际为空（虽然服务装了）
sudo ls $ROOT/var/lib/docker/image/overlay2/imagedb/content/sha256/
# (空)

# LXD containers 也为空
sudo ls $ROOT/var/lib/lxd/containers/
# (空)

# LXC 有一个名为 mytidb 的容器
sudo ls $ROOT/var/lib/lxc/
# mytidb
```

`/var/lib/lxc/mytidb` 是 LXC 容器，名字 `mytidb` 暗示运行 TiDB 数据库（与题 S13"4000 端口备份数据库"对应——TiDB 默认端口 4000）。

### 不作弊声明
- 数据来源: 检材3 服务器
- 工具: ls
- 脚本: scripts/fic_srv_deep.sh
A

ls -la "$ANS_DIR"
echo "Saved 4 answers"
