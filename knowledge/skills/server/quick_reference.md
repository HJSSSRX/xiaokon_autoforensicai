# Server Forensics — Quick Reference

tags: server, linux, docker, nginx, tidb, mysql, btrfs, xfs, lvm, baota, maccms

---

## 一、第一步: 画架构地图 (不画不准答题)

**30 分钟完成以下 5 件事后才开始答题**:

```bash
# 1. 识别两个 E01 的文件系统
mmls 检材3-1.E01
mmls 检材3-2.E01
# → 决定: 同一台机器(rootfs + data) 还是两台服务器

# 2. 挂载并找 OS 信息
cat /etc/os-release           # Q1: OS 版本
cat /etc/fstab                # 文件系统类型 → Q16
blkid                         # UUID → Q2

# 3. 列 Docker 容器/镜像
ls /var/lib/docker/image/overlay2/imagedb/content/sha256/
cat /var/lib/docker/image/overlay2/repositories.json
# → Docker 时间戳 → Q3, 容器技术 → Q12, 数据库服务 → Q17

# 4. 找 Web 服务
find / -name "nginx.conf" -o -name "apache2.conf" -o -name "www.conf" 2>/dev/null
cat /www/server/panel/config/config.json   # 宝塔面板配置
# → 后台入口文件 → Q5, ICP → Q6, 主域名 → Q7

# 5. 找数据库连接
grep -r "DB_HOST\|database_url\|mysql://\|db_host" /www /app /srv 2>/dev/null | head -20
# → 关联数据库 IP → Q11
```

**架构地图模板** (写到 case/server/architecture_map.md):
```
磁盘布局:
  E01-1: rootfs (ext4/btrfs) + swap
  E01-2: data (/data, xfs/lvm)

OS: Debian 12 / Ubuntu 22.04 / CentOS 8

Web 层:
  Nginx 监听 80/443 → 反代 PHP-FPM 8080
  宝塔面板 / 手动配置

应用:
  MacCMS 10 (PHP) | WordPress | 自定义 Node.js

数据库:
  主 DB: MySQL/TiDB @ 127.0.0.1:4000 / 3306 (Docker 容器)
  备份: TiDB @ 4000 端口

Docker:
  镜像: [列出 imagedb 里的条目]
  最新创建时间: [Q3]

Btrfs/LVM:
  快照路径: [Q4]
```

---

## 二、文件系统挂载速查

### E01 → ext4/btrfs/xfs (WSL)

```bash
# 1. 挂载 E01
ewfmount /mnt/e/ffffff-JIANCAI/检材3-服务器/检材3-1.E01 /mnt/ewf1
losetup -P /dev/loop0 /mnt/ewf1/ewf1

# 2. 看分区
lsblk /dev/loop0
fdisk -l /dev/loop0

# 3. 挂载文件系统
mount /dev/loop0p1 /mnt/srv1 -o ro            # ext4
mount /dev/loop0p1 /mnt/srv1 -o ro,subvol=@  # btrfs (根子卷)

# 4. Btrfs 列子卷和快照 → Q4
btrfs subvolume list /mnt/srv1
```

### LVM 解锁 (如果有 LVM)

```bash
# 扫描 LV
kpartx -a /dev/loop0
pvs && vgs && lvs
vgchange -ay VolGroup
mount /dev/VolGroup/lv_root /mnt/lv_root -o ro
```

### E01 → Python (Windows 端, 无需 WSL)

```python
from dissect.target import Target
t = Target.open(r"E:\检材3-服务器\检材3-1.E01")
# 列根目录
for f in t.fs.path("/").iterdir(): print(f)
# 读文件
print(t.fs.path("/etc/os-release").read_text())
```

---

## 三、Docker 分析

```bash
# 列镜像 (静态分析, 不需要 Docker daemon)
ls /var/lib/docker/image/overlay2/imagedb/content/sha256/
# 读 manifest 获取创建时间 → Q3
python3 -c "
import json, os, glob
for f in glob.glob('/var/lib/docker/image/overlay2/imagedb/content/sha256/*'):
    d = json.load(open(f))
    print(d.get('created',''), os.path.basename(f)[:16])
" | sort

# 容器配置 → 找环境变量 (DB 密码/主机等)
cat /var/lib/docker/containers/*/config.v2.json | python3 -m json.tool
```

---

## 四、Web 应用分析 (MacCMS / 宝塔)

### 宝塔面板常见路径
```
/www/wwwroot/              主网站目录
/www/server/panel/         宝塔面板
/www/server/nginx/conf/    Nginx 配置
/www/server/mysql/         MySQL 数据目录
/www/backup/               备份目录
```

### MacCMS 10 数据结构
```sql
-- 后台入口 → Q5: 通常是自定义的 admin_*.php
SELECT value FROM mac_config WHERE key='admin_dir';

-- ICP 备案号 → Q6
SELECT value FROM mac_config WHERE key='icp';

-- 主域名 → Q7
SELECT value FROM mac_config WHERE key='domain';

-- 分类 → Q8: 视频拼音
SELECT type_name, type_en FROM mac_type WHERE type_id=3;

-- 模板 → Q9
SELECT value FROM mac_config WHERE key='template';  -- 通常 'template/default'

-- 注册用户最多日期 → Q14
SELECT DATE(mem_time) d, COUNT(*) c FROM mac_member GROUP BY d ORDER BY c DESC LIMIT 5;

-- 用户最后登录 → Q15
SELECT mem_last_loginip FROM mac_member WHERE mem_name='马慧美';
```

### SM3 哈希计算 → Q10
```python
# pip install gmssl
from gmssl.sm3 import sm3_hash
with open("rewrite.conf", "rb") as f:
    data = list(f.read())
print(sm3_hash(data).upper())   # 答案通常是大写 hex
```

---

## 五、TiDB 分析 → Q13

```bash
# 在镜像里找 TiDB 版本
find / -name "tidb-server" -o -name "tidb" 2>/dev/null
/path/to/tidb-server -V       # 输出 "Release Version: v7.x.x"

# TiDB 4000 端口配置
cat /etc/tidb/*.toml | grep -i "port\|version"
find / -path "*/tidb/*.toml" 2>/dev/null
```

---

## 六、互联网取证线索位置

| 题目 | 线索来源 |
|---|---|
| ngrok 域名 → Q3 | Nginx upstream / Docker ENV / app config / strings on exe |
| 卡密群组 ID → Q1 | 数据库 `config` 表 / 源码 hardcode / Telegram bot token 旁边 |
| 备份 DB 图片文件 → Q2 | 数据库 `attachment`/`media` 表 / 备份 SQL dump |

---

## 七、经验铁律

> **错因 1** (通用): 没画架构地图就钻题 → 钻完 Q1 发现 Q11 (数据库 IP) 其实在 Docker ENV 里, 早知道能一次搞定
> **铁律**: 架构地图画完后, 80% 题目的文件位置立刻清晰

> **错因 2** (2025 某届): 两个 E01 以为是两台服务器 → 其实是同一台 (rootfs + data) → 浪费 1 小时
> **铁律**: `mmls` 看完后, 对比分区表 + UUID, 确认关系再动手

> **错因 3**: SM3 直接用 hashlib.md5 → SM3 是国密, 要用 gmssl 或 openssl sm3
> **铁律**: `python -c "from gmssl.sm3 import sm3_hash; print('OK')"`  先确认 gmssl 可用

---

## 八、答案格式速查 (server_forensics)

| 题目类型 | 标准格式 | 例子 |
|---|---|---|
| OS 版本 | 主.次 (纯数字) | `12.5` 或 `0.9` |
| 硬盘 UUID | hex-hex 格式 | `a1b2c3d4-e5f6` |
| Docker 时间戳 | ISO 8601 + 纳秒 + Z | `2020-01-01T00:00:00.012345678Z` |
| Btrfs 快照路径 | Unix 绝对路径 | `/.snapshots/1/snapshot` |
| 后台文件名 | 含扩展名 | `admin2025.php` |
| ICP 备案号 | 原字符串 | `粤ICP备2024012345号` |
| 主域名 | 纯域名, 不含 http | `example.com` |
| 分类拼音 | 纯拼音小写 | `zongyi` |
| 模板源文件 | 文件名.扩展名 | `YMYS002.html` |
| SM3 | 64 hex 大写 | `09D001DA...` |
| 数据库 IP | IPv4 | `172.17.0.2` |
| 容器技术 | 纯名称小写 | `docker` |
| 备份 DB 版本 | vX.Y.Z | `v7.5.2` |
| 日期 | yyyy/m/d | `2026/1/1` |
| 登录 IP | IPv4 | `1.2.3.4` |
| 文件系统(未使用) | 单选 A/B/C/D | `A` |
| 数据库(多选) | 字母组合 | `ACD` |
