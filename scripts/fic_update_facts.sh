#!/usr/bin/env bash
FACTS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/facts.md"

cat >> "$FACTS" <<'F'

---

## 2026-04-25 13:18 [MAIN] 服务器深挖发现汇总

### 服务器架构
- **OS**: Debian 13 (trixie)
- **存储**: btrfs on RAID0 (双盘条带), btrfs UUID=3231e52f-5e15-44c4-b224-e29cb4201c0e
- **btrfs 子卷**: @rootfs (主), @rootfs/root/history (快照, ID 257)
- **LVM**: VG `volum`/`root` 各一个 PV，组 RAID0 后 btrfs
- **Docker root 改在 /data**（非默认 /var/lib/docker），14 个镜像

### 网站 = MacCMS V10
- 路径: `/var/www/html/maccms10/`
- 数据库配置 (`application/database.php`):
  - hostname: `mytidb` → IP **10.0.3.100** (LXC 容器)
  - port: 3306
  - database: `mac2`
  - user: `aa`
  - password: `123456`
- nginx default site 直接 `root /var/www/html/maccms10`

### 关键容器
- **LXC mytidb**: rootfs path = `/db/tidb`，IP=10.0.3.100，承载 MySQL/TiDB
  - LXC 容器开机自启 (`lxc.start.auto = 1`)
- **Docker 容器 u24**: image=u22:latest，running=true，Created=2026-04-16T10:09:05Z
  - `docker start u24` 出现在 mac 用户 bash_history

### 关键工具
- ngrok 装在 `/usr/local/bin/ngrok`，配置 `/root/.config/ngrok/ngrok.yml`
  - authtoken: `3CI1uKfId6H6LQQSy7Mch7kijxN_5qo6D7Thu7hBdHMFXaw4W`
  - bash_history 显示用过 `ngrok http 80`
- PostgreSQL 17（主机）
- LXD (空 containers)、ZFS

### 用户 / 关键路径
- 唯一普通用户: `mac` UID=1000
- mac 用户 .bash_history 显示: `docker start u24`、`startx`、xinit 折腾
- root .bash_history 显示: `lxc-attach mytidb`、`ngrok http 80`、`vi database.php`

### 网络配置
- /etc/hosts: 10.0.3.100 mytidb
- LXC 默认网桥 lxcbr0
- WSL 实际宿主网络（非 Linux 服务器）：172.27.23.25/20

---
F

# 给 PHONE 追加重要发现
cat >> "/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/inbox/phone.md" <<'P'

---

## 🔥 MAIN 发现的关键 IOC（PHONE 可复用）

### 网站后端有 maccms10
- 数据库密码 `123456` (用户 aa)
- 服务器跑在 **mytidb (10.0.3.100)** LXC 容器
- 主机操作系统 Debian 13

### 已知账号/口令字典（如果手机里有跨检材题）
- aa / 123456 (maccms 数据库)
- mac (服务器 Linux 用户)

### 题目互通提示
- M03 "与网站搭建人员沟通" → 服务器站长是 root/mac，沟通可能用 IM
- M07 "第一次转账 hash" → 钱包地址互通服务器
F
P

echo "facts.md 和 phone inbox 已更新"
wc -l "$FACTS"
