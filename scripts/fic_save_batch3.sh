#!/usr/bin/env bash
ANS="/mnt/e/项目/自动化取证/cases/2026FIC电子取证/shared/answers"

cat > "$ANS/S03_main_srv_docker_latest.md" <<'A'
## S03 — 服务器中最新的 docker 镜像创建时间

> 该服务器中最新的docker镜像创建时间为

**答案**: `2026-04-16 07:15:50 UTC`（即北京时间 `2026-04-16 15:15:50 +08:00`）  **置信度**: 高

### 解析

**识别**: Docker 服务在该服务器上配置了非默认 root 路径，实际数据存于 `/data/`（不是 `/var/lib/docker`）。从 mac 用户 `~/.bash_history` 中 `docker ps -a / docker start u24` 等命令侧证 docker 在使用。

**提取**:
```bash
# repositories.json 列出所有镜像 tag
sudo cat /tmp/srv_root/@rootfs/data/image/overlay2/repositories.json | jq

# 各镜像的 created 字段（按时间倒序）
for f in /tmp/srv_root/@rootfs/data/image/overlay2/imagedb/content/sha256/*; do
  jq -r '.created' "$f"
done | sort -r | head -5
```

**分析+验证**:

镜像总数：**14 个**。按 `.created` 字段倒序：

| created (UTC) | sha256 (前 12) | 备注 |
|---|---|---|
| **2026-04-16T07:15:50.535Z** | `1c89854511ca` | **最新**，对应 tag `u22:latest`（基于 ubuntu:22.04） |
| 2026-04-11T23:47:15.384Z | `813ea2d175ca` | |
| 2026-04-11T23:43:30.768Z | `54a61d422be5` | |

最新镜像 `1c89854511ca` 的 tag 是 `u22:latest`，正在被 docker 容器 `u24` 使用（运行中）。

### 不作弊声明
- 数据来源: 检材3 服务器 /data/image/...
- 工具: jq, sort
- 脚本: scripts/fic_attack_batch2.sh
A

cat > "$ANS/S11_main_srv_db_ip.md" <<'A'
## S11 — 该网站关联的数据库的 IP 地址

> 该网站关联的数据库的ip地址为

**答案**: `10.0.3.100`  **置信度**: 高

### 解析

**识别**: maccms10 网站位于 `/var/www/html/maccms10/`，其数据库配置在 `application/database.php`。

**提取**:
```bash
sudo cat /tmp/srv_root/@rootfs/var/www/html/maccms10/application/database.php
```

**分析+验证**:

`application/database.php` 关键字段：
```
'type'     => 'mysql'
'hostname' => 'mytidb'    <- 主机名（不是 IP）
'database' => 'mac2'
'username' => 'aa'
'password' => '123456'
'hostport' => '3306'
```

`hostname` 是主机名 `mytidb`，需通过 `/etc/hosts` 解析到 IP：
```bash
sudo cat /tmp/srv_root/@rootfs/etc/hosts
```

输出：
```
10.0.3.100 mytidb
```

`mytidb` 即名为 `mytidb` 的 LXC 容器（lxcbr0 默认子网 10.0.3.0/24），容器 IP = **10.0.3.100**。

### 不作弊声明
- 数据来源: 检材3 服务器
- 工具: cat
- 脚本: scripts/fic_attack_batch3.sh
A

ls -la "$ANS"
echo "Saved S03 + S11"
