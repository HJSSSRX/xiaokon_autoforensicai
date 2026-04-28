# Playbook · Linux 服务器镜像

## 0. 挂载

```bash
# 单分区 raw
sudo mount -o ro,loop,noexec $IMG $MNT

# 有分区表的
fdisk -l $IMG               # 找起始扇区
sudo mount -o ro,loop,offset=$((START*512)) $IMG $MNT

# LVM
sudo losetup -fP $IMG
sudo vgscan && sudo vgchange -ay
sudo mount -o ro /dev/<vg>/<lv> $MNT
```

---

## 1. 系统信息

| 问题 | 看哪里 |
|---|---|
| 发行版 | `$MNT/etc/os-release` |
| 内核版本 | `ls $MNT/boot/vmlinuz-*` 或 `ls $MNT/lib/modules/` |
| 主机名 | `$MNT/etc/hostname` |
| 时区 | `$MNT/etc/timezone` 或 `readlink $MNT/etc/localtime` |
| 安装时间 | `stat $MNT/lost+found` 或 `tune2fs -l $(losetup ...) | grep created` |
| 最后开机 | `$MNT/var/log/wtmp` 尾部 |

```bash
last -f $MNT/var/log/wtmp        # 登录+开关机
last -f $MNT/var/log/btmp        # 失败登录
lastlog -R $MNT                  # 每用户最后登录
```

---

## 2. 用户 / 登录

| 问题 | 位置 |
|---|---|
| 所有用户 | `/etc/passwd`（含系统用户）、`/etc/shadow` |
| 非系统用户 | `awk -F: '$3>=1000' /etc/passwd` |
| 登录成功次数 | `last -f wtmp` 行数，或 `grep 'Accepted' /var/log/auth.log* | wc -l` |
| SSH 公钥 | `~/.ssh/authorized_keys` |
| sudo 记录 | `/var/log/auth.log` 或 `/var/log/secure` |

---

## 3. 应用服务（Web / 数据库 / 中间件）

### 定位服务

```bash
# systemd 服务单元
ls $MNT/etc/systemd/system/*.service $MNT/lib/systemd/system/*.service

# 自启动
ls $MNT/etc/systemd/system/multi-user.target.wants/

# 运行时数据
ls $MNT/var/lib/ $MNT/opt/ $MNT/srv/
```

### 常见服务定位速查

| 服务 | 配置 | 数据 | 日志 |
|---|---|---|---|
| nginx | `/etc/nginx/` | `/var/www/` | `/var/log/nginx/` |
| apache | `/etc/apache2/` 或 `/etc/httpd/` | 同上 | `/var/log/apache2/` |
| MySQL | `/etc/mysql/` | `/var/lib/mysql/` | `/var/log/mysql/` |
| PostgreSQL | `/etc/postgresql/` | `/var/lib/postgresql/` | |
| Redis | `/etc/redis/redis.conf` (含 `requirepass`) | `/var/lib/redis/` | |
| MongoDB | `/etc/mongod.conf` | `/var/lib/mongodb/` | |
| Docker | `/etc/docker/` | `/var/lib/docker/` | |
| Trojan / V2Ray | `/etc/trojan/` `/etc/v2ray/` | | |

### Web 应用常见

```bash
# 找所有 PHP/Python/Node 代码
find $MNT/var/www $MNT/opt $MNT/srv -type d -maxdepth 3

# 找 .env / 配置
find $MNT -name '.env' -o -name 'config.json' -o -name 'settings.py' 2>/dev/null

# 数据库连接串
rg -l 'DB_PASSWORD|database_url|mysql://|postgres://' $MNT
```

### Redis 密码

`/etc/redis/redis.conf` 搜 `requirepass`。**常见备份位置**：`/root/.redis_history`、Docker 容器配置。

### MySQL 用户

```bash
# 离线读 mysql.user 表（MyISAM 或 InnoDB）
# 简单：复制 /var/lib/mysql 到另一台，启动 mysqld --skip-grant-tables --datadir=... 再 dump
# 或：读 mysql/user.frm + user.MYD
```

---

## 4. Web 后台分析（高频考点）

### 判题模式
- "网站后台密码加密算法是什么"
- "给定密码 X，加密后存在数据库里的值是什么"（复现加密逻辑）
- "用 rockyou 爆破管理员密码"

### 典型做法

1. **找代码**：`find /var/www -name '*.py' -o -name '*.php' -o -name '*.js' | xargs rg -l 'login|password|hash|bcrypt|md5'`
2. **读登录/注册函数**，定位加密逻辑
3. **AI 读源码后有两种产出**：
   - 直接告诉加密方式（Q21 类型："用 bcrypt" / "MD5 加盐"）
   - **写一个复现脚本**（Q55 类型："给定明文，算出数据库里存的密文"）

### 常见加密

```python
# bcrypt
import bcrypt
bcrypt.hashpw(pw.encode(), bcrypt.gensalt(rounds=12))

# MD5 加盐
import hashlib
hashlib.md5((pw + salt).encode()).hexdigest()

# PHP 典型
password_hash($pw, PASSWORD_BCRYPT)
password_hash($pw, PASSWORD_DEFAULT)
```

### 爆破

```bash
# bcrypt
hashcat -m 3200 hashes.txt /usr/share/wordlists/rockyou.txt

# MD5
hashcat -m 0 hashes.txt rockyou.txt
```

---

## 5. 攻击痕迹 / 入侵分析

### 判题模式
- "攻击者 IP 是什么"
- "webshell 文件名 / sha256"
- "哪个 IP 上传了木马"

### 看哪里

```bash
# Web 日志按 POST 筛
rg 'POST' $MNT/var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head

# 找 webshell 特征
rg -l 'eval\(\$_POST|base64_decode\(\$_|assert\(\$_' $MNT/var/www

# 找近期上传
find $MNT/var/www -type f -newermt '2024-01-01' -ls

# bash 历史（攻击后）
cat $MNT/root/.bash_history
cat $MNT/home/*/.bash_history
```

---

## 6. 脚本行为复现题（平航杯 2025/2026 特色）

### 判题模式
出题给一个 Python 或 Bash 函数，让你通过**黑盒测试**推断参数：
- "某函数 UA 白名单有几个"
- "时间窗口阈值是多少毫秒"
- "触发概率 1/N 中的 N 是多少"

### 做法

1. **静态读代码**（首选）：如果源码可访问，`rg` 出函数直接看 → 秒答
2. **黑盒复现**：源码看不到时写 Python 复现：
   - 固定一个变量，遍历另一个
   - 例 Q28：固定 UA，从 0~1000ms 遍历 IP 间隔，找"命中→不命中"的临界点
   - 每个间隔值测 ≥200 次消除概率干扰

### AI 在这类题上的优势

**极大**。LLM 读代码比跑工具快 10 倍。这是 .md 里最该投资的题型。

---

## 7. 容器 / Docker

```bash
# 所有容器配置
ls $MNT/var/lib/docker/containers/*/config.v2.json | xargs -I{} jq '.Name, .Image, .Config.Cmd' {}

# 找挂载卷
jq '.MountPoints' $MNT/var/lib/docker/containers/*/config.v2.json

# 从 overlay2 提取容器文件系统
ls $MNT/var/lib/docker/overlay2/<ID>/diff/
```

---

## 8. 常见坑

- **大小写敏感**：Linux 文件系统大小写敏感，Windows 习惯查起来会漏
- **软链**：`/etc/localtime` 指向 `/usr/share/zoneinfo/Asia/Shanghai`，要 readlink
- **Docker 里有应用**：主机 `/var/www` 空不代表网站没了，可能在 docker 卷里
- **日志轮转**：`.log`、`.log.1`、`.log.2.gz` 都要看，`zcat` 读 gz
- **history 丢失**：很多攻击者会 `unset HISTFILE` 或 `rm -rf ~/.bash_history`
