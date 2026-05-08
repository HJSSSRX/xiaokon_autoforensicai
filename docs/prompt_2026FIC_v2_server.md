# 续战提示词 v2 — server_analyst (2026FIC 服务器+互联网+手机协助)

> Hub IP 已固化为 `172.21.183.206`。把下面三反引号之间的整段粘给 server 机的 AI 即可。

---

```
你是 2026FIC 比赛的 server_analyst（服务器+互联网取证分析员），现在续接进度。
不要回复任何客套话，立即按下面执行。

━━━ 当前真实状态（来自 DIDCTF 平台） ━━━

[服务器取证 17 题, 已确认 2, 剩 15]
- ✅ Q3 docker镜像创建时间 = 2026-04-16T07:15:50.535713491Z
- ✅ Q11 数据库 IP = 10.0.3.100
- ❌ Q1 OS版本 (我们答 "13.0", 平台不认; 参考格式 "0.9")
- ❌ Q2 根分区 UUID (参考格式 a1b2-c3, 即包含连字符的分段格式)
- ❌ Q4 根分区快照路径 (参考格式 /abc/def, 即 /something/something)
- ❌ Q5 网站后台管理入口文件名 (参考格式 123.txt, 即 *.php)
- ❌ Q6 网站 ICP 备案号 (参考格式 icp123)
- ❌ Q7 网站主域名 (参考格式 abc.com)
- ❌ Q8 网站分类3视频拼音 (参考格式 abc)
- ❌ Q9 站点设置前端模板源文件 (参考格式 abc.def)
- ❌ Q10 伪静态规则配置文件 SM3 hash (参考格式 ABC123)
- ❌ Q12 数据库容器技术 (参考格式 abc, 应该是 docker / podman / lxc)
- ❌ Q13 4000端口备份数据库版本 (参考格式 v1.1.1)
- ❌ Q14 注册用户最多日期 (参考格式 2000/1/1)
- ❌ Q15 马慧美最后登录IP (参考格式 1.1.1.1)
- ❌ Q16 单选 文件系统未被使用 (A.ntfs B.btrfs C.xfs D.Lvm)
- ❌ Q17 多选 数据库服务 (A.mysql B.GuessDB C.tidb D.postgresql E.Mariadb)

[互联网取证 3 题, 已确认 2, 剩 1]
- ✅ Q1 卡密群组ID = FIC_2026
- ✅ Q3 ngrok域名 = blemish-junior-unengaged.ngrok-free.dev
- ❌ Q2 备份数据库视频图片文件名 (参考格式 abc.png)

━━━ 重大新线索（题目页面已给出！） ━━━
🔑 挂载密码 = FIC-{e404d6e66586e9460c23755afab5a872bcf78ab4}
   → 这就是你之前推测的 cryptsetup 密码！直接用！

━━━ 强制阅读顺序 ━━━
1. case\server\HANDOFF*.md / PROGRESS.md                   ← 之前交接
2. case\shared\todo.yaml (server_forensics 段)             ← 待解 15 题
3. case\shared\diff_report.md                              ← 答案对比
4. case\shared\findings.yaml (F-S001~F-S025)               ← 你的发现
5. E:\项目\自动化取证\knowledge\skills\server\quick_reference.md
6. E:\项目\自动化取证\knowledge\skills\web\baota_panel_forensics.md

━━━ 心跳协议（v2 闭环必须遵守） ━━━
主指挥 (captain/main_designer) 通过 watcher 主动向你发广播指令。
你必须:
1. 每完成一个步骤, 立即 POST /findings 汇报
2. 每完成一题, POST /answers 后立即 GET http://172.21.183.206:8765/findings?from=main_designer
3. 看到 type="instruction" 且 target_roles 包含 "server_analyst" 的 finding, 优先处理
4. 超过 30 分钟无进展时, POST heartbeat finding 证明你活着

```python
import urllib.request, json
r = urllib.request.urlopen("http://172.21.183.206:8765/findings?from=main_designer", timeout=3)
for inst in [f for f in json.loads(r.read()) if f.get("type")=="instruction"][-5:]:
    if "server_analyst" in inst.get("target_roles", []):
        print(f"[指挥] {inst['summary']}")
```

━━━ 你今天的 4 步行动 ━━━

【Step 1: WSL 挂载 LVM 加密分区（关键，解锁全部题）】
切到 WSL Ubuntu (用户 hjsssr，密码 E:\项目\psw 第一行):
```bash
sudo apt install -y ewf-tools cryptsetup btrfs-progs lvm2

# 1. ewfmount 两个 E01
mkdir -p /mnt/e1 /mnt/e2 /mnt/server_root /mnt/server_data
sudo ewfmount '/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材3-服务器/检材3-1.E01' /mnt/e1
sudo ewfmount '/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材3-服务器/检材3-2.E01' /mnt/e2

# 2. losetup 创建 loop device (含分区表)
sudo losetup -fP /mnt/e1/ewf1
sudo losetup -fP /mnt/e2/ewf1
sudo losetup -a   # 看 /dev/loop0 /dev/loop1

# 3. LVM 扫描+激活
sudo pvscan
sudo vgscan
sudo vgchange -ay
sudo lvs   # 应看到 volum/data, root/root 等

# 4. 解密 LV root (用题目给的密码!)
sudo cryptsetup open /dev/root/root server_root \
    --type plain --cipher aes-xts-plain64 --key-size 512 --hash sha256
# 密码: FIC-{e404d6e66586e9460c23755afab5a872bcf78ab4}

# 如 plain 模式不行, 试 LUKS:
sudo cryptsetup luksOpen /dev/root/root server_root
# 密码同上

sudo mount -o ro /dev/mapper/server_root /mnt/server_root
ls /mnt/server_root/   # 应看到 etc/ var/ home/ 等

# 5. 挂载 btrfs (LV data, 不需密码)
sudo mount -o ro /dev/volum/data /mnt/server_data
ls /mnt/server_data/  # docker镜像 / 网站文件 / 数据库
```

【Step 2: 系统性解题（按依赖顺序）】

— Q1 OS版本（参考 "0.9"）—
```bash
cat /mnt/server_root/etc/os-release | grep VERSION_ID
# 我们之前答"13.0"被拒, 可能要纯版本号 "13" 或 "13.1" 或 "trixie"
# 也试: cat /etc/debian_version
```

— Q2 根分区 UUID（参考 a1b2-c3）—
```bash
sudo blkid /dev/mapper/server_root
# 例: UUID="abcd1234-5678-..." → 答案可能要短格式 "abcd-1234"
# 也用 lsblk -f
```

— Q4 根分区快照路径（参考 /abc/def）—
```bash
# btrfs 子卷
sudo btrfs subvolume list /mnt/server_data
# 或在 root 上找 timeshift / snapper
ls /mnt/server_root/.snapshots/
ls /mnt/server_root/var/lib/snapper/
```

— Q5 网站后台管理入口文件 (改名的 admin.php) —
```bash
# 找 maccms 后台
find /mnt/server_data -path "*/maccms*/admin*.php"
ls /mnt/server_data/www/wwwroot/*/application/admin/   # 看 controller
# 通常 web 入口被改名: 看 nginx conf 中的 rewrite 规则
grep -r "admin" /mnt/server_data/www/server/panel/vhost/nginx/
```

— Q6 ICP 备案号（参考 icp123）—
```bash
grep -rE "ICP|icp.*[0-9]{4,}" /mnt/server_data/www/wwwroot/*/template/
grep -rE "ICP|icp.*[0-9]{4,}" /mnt/server_data/www/wwwroot/*/public/
# 也搜 access.log 中含 beian 的
```

— Q7 主域名（参考 abc.com）—
```bash
# nginx server_name
grep -h server_name /mnt/server_data/www/server/panel/vhost/nginx/*.conf
# 站点列表
ls /mnt/server_data/www/wwwroot/
# 不要选 ngrok 那个 (那是 Q3), 找正经域名
```

— Q8 视频分类 3 拼音（参考 abc）—
```bash
# maccms 数据库 mac_type 表
sqlite3 /mnt/server_data/www/wwwroot/maccms/runtime/cache/*.db "SELECT * FROM mac_type;"
# 或 mysqldump 备份: type_id=3 的 type_en (拼音字段)
grep -A2 "type_id.*3" /mnt/server_data/var/lib/mysql/*/mac_type.MYD 2>/dev/null
# 或导入 sql 备份后查
```

— Q9 前端模板源文件（参考 abc.def）—
```bash
# 找站点设置, 模板配置
grep -r "template\|theme" /mnt/server_data/www/wwwroot/maccms/application/
# 答案常见: maccms.zip (模板包), 或 xxx.html.zip
```

— Q10 伪静态规则 SM3（参考 ABC123）—
```bash
# 宝塔伪静态文件位置
find /mnt/server_data/www/server/panel/vhost/rewrite/ -type f
# SM3 hash:
python3 -c "from gmssl import sm3, func; \
import sys; data=open(sys.argv[1],'rb').read(); \
print(sm3.sm3_hash(func.bytes_to_list(data)).upper())" \
<伪静态文件>
# pip install gmssl 如未装
```

— Q12 数据库容器技术（参考 abc, 答 docker/podman/lxc）—
```bash
# 看 docker / podman 安装
ls /mnt/server_data/var/lib/docker/   # 如有 → docker
which podman / which lxc
# Q11 已答 IP=10.0.3.100, 这是 docker bridge 网段, 答案应该是 "docker"
```

— Q13 4000端口备份数据库版本（参考 v1.1.1）—
```bash
# 4000端口默认 = TiDB, 已知服务器装了 tidb
grep -r "4000" /mnt/server_data/etc/ /mnt/server_data/root/ 2>/dev/null
# 找 tidb 二进制或 docker image:
ls /mnt/server_data/var/lib/docker/containers/ -la
# tidb-server --version 输出 "TiDB Server v8.x.x"
```

— Q14 新注册用户最多日期 / Q15 马慧美登录IP —
```bash
# 用户表导出
sqlite3 ... 或 mysql 备份分析
# Q14: SELECT DATE(created_at), COUNT(*) FROM users GROUP BY DATE(created_at) ORDER BY 2 DESC LIMIT 1;
# Q15: SELECT ip FROM user_login_log WHERE username='马慧美' ORDER BY login_at DESC LIMIT 1;
```

— Q16 单选 文件系统未被使用 —
```bash
# 已知: btrfs (LV data) ✓, LVM ✓, NTFS ?, XFS ?
# 看 fstab + 全盘 file -s
sudo file -s /dev/loop0p* /dev/loop1p* /dev/mapper/server_root
mount | grep -E "ntfs|btrfs|xfs|ext"
# 答案: 选未被使用的那个 (常见 NTFS 在 Linux 服务器没用)
```

— Q17 多选 数据库服务 —
```bash
# 已知: postgresql ✓ (F-S004), mysql ?, tidb ✓ (4000端口), mariadb ?
ls /mnt/server_data/var/lib/{postgresql,mysql,mariadb,tidb,tikv,pd}/ 2>/dev/null
# 看 docker images
ls /mnt/server_data/var/lib/docker/image/overlay2/repositories.json
# B.GuessDB 是迷惑选项, 排除
```

【Step 3: 互联网 Q2 (备份数据库中视频图片文件名)】
```bash
# 在 SQL 备份里找 image / pic 字段
grep -rE "\.(jpg|png|gif).*pic|pic.*\.(jpg|png|gif)" /mnt/server_data/www/backup/
# 或在 maccms vod 表的 vod_pic 字段
```

【Step 4: 全部解出后清空 blocker】
```python
# Hub 标记 blocker resolved
post("/session/blocker", {"id":"B001","status":"resolved",
     "note":"WSL 挂 LVM + cryptsetup 用题目给的挂载密码成功"})
```

━━━ 协作铁律 ━━━
```python
import urllib.request, json
def post(path, data):
    body = json.dumps(data, ensure_ascii=False).encode("utf-8")
    return urllib.request.urlopen(
      urllib.request.Request(f"http://172.21.183.206:8765{path}",
        data=body,
        headers={"Content-Type":"application/json; charset=utf-8"},
        method="POST")).read().decode("utf-8")

# 每解一题立即 POST
post("/answers", {"category":"server_forensics","qid":"Q1",
     "answer":"13","analysis":"...","evidence_path":"...",
     "source_role":"server_analyst","confidence":"high"})
```

━━━ 答案格式硬要求 ━━━
- 跑完每题用 lint 复核
- IP 必须是 a.b.c.d (不能多空格)
- UUID 看格式提示是分段还是完整
- SM3/MD5 大写还是小写按提示

━━━ 完成定义 ━━━
- LV root + LV data 都成功挂载
- 服务器 17 题至少 12 题 high confidence
- 互联网 3 题全部 high confidence
- 写 case\server\SOLVED_v2.md

立即开始 Step 1（挂 LVM）。
```
