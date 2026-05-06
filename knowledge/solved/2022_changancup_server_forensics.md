---
tags: [server_forensics, linux, jar, docker, mysql, database_recovery, web_reconstruction, ssh, centos]
tools: [火眼, cat, ifconfig, netstat, docker, docker-compose, mysql, sshpass, grep]
category: server_forensics
difficulty: medium
source: 2022_changancup
date: 2026-05-05
verified: true
---
# Title: 2022长安杯 — 服务器取证（检材1&3）

## Problem
虚拟币交易网站诈骗案，需分析多个服务器镜像，包括网站前后端服务器、数据库、Docker 容器等。

## Solution Steps

### 检材1 — Linux 网站前端服务器

1. 查看操作系统版本
   ```
   cat /etc/redhat-release
   ```

2. 查看网卡静态IP
   ```
   ifconfig
   ```

3. 通过 history 查看网站 jar 包目录
   ```
   history | grep cd
   ```
   → 发现多次进入 `/web/app` 目录

4. 查看 jar 包监听端口 — 反编译 jar 包查找端口配置
   → `cloud.jar` 使用 7000 端口

5. 通过启动脚本 `start_web.sh` 确定各端口用途
   → 9090 端口为管理后台，3000 端口为前台

6. 反编译 `admin-api.jar` 查找密码加密方式
   → 发现 `md5.key=XehGyeyrVgOV4P8Uf70REVpIw3iVNwNs`（盐值）
   → 密码使用 MD5+盐值 加密

### 检材3 — Linux 数据库服务器

7. 查看 Docker 配置
   ```
   cat /data/mysql/docker-compose.yml
   ```
   → 33050 端口映射到容器内 MySQL
   → 数据目录挂载: `/data/mysql/db` → 容器内 `/var/lib/mysql`

8. 从 `admin-api.jar` 配置中获取数据库密码和库名
   → 数据库名: `b1`

9. 分析 MySQL 日志 `/data/mysql/db/8eda4cb0b452.log`
   ```
   grep "UPDATE.*member.*mobile_phone" 8eda4cb0b452.log
   ```
   → 勒索者修改了 3 个用户手机号

10. 分析删除操作
    ```
    grep "DELETE FROM.*member" 8eda4cb0b452.log
    ```
    → 删除了 id 973-1000 共 28 个用户

11. 还原数据库 — 将检材2中的 b1 数据库文件拷贝回检材3
    ```
    docker exec -it <container_id> bash
    mysql -u root -p
    ```

## Key Takeaways
- Linux 服务器先看 `/etc/*-release` 确定发行版
- `history` 命令是重要的行为审计来源
- jar 包可反编译获取数据库连接、密码、盐值等配置
- Docker 取证: `docker-compose.yml` 包含端口映射、卷挂载、环境变量
- MySQL 日志(general log)记录所有 SQL 操作，可用于还原被篡改数据
- 数据库还原思路: 从其他检材获取备份数据，替换被删除的数据文件
