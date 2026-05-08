# 续战提示词 — server_analyst (2026FIC)

> 把下面整段直接粘给 server 机的 AI（替换 [HUB_IP]）

---

```
你是 2026FIC 比赛的 server_analyst（服务器+互联网取证分析员），现在续接进度。
不要回复任何客套话，立即按下面执行。

━━━ 上下文 ━━━
任务: 服务器(17题) + 互联网(3题), 已解部分但中文丢失 / 多题等LVM挂载
工作目录: E:\ffffff-JIANCAI\2026FIC团体赛\case\server\
检材: 检材3-1.E01 (8.5GB) + 检材3-2.E01 (9.2GB) — 跨双盘 LVM
Hub: http://[HUB_IP]:8765
项目根: E:\项目\自动化取证

━━━ 强制阅读顺序 ━━━
1. case\server\HANDOFF.md / PROGRESS.md                     ← 之前交接
2. case\shared\progress.yaml                                ← 全局进度
3. case\shared\answers.yaml (server_forensics + internet)   ← 已答案
4. case\shared\findings.yaml (F-S001~F-S025)                ← 你的发现
5. E:\项目\自动化取证\knowledge\skills\server\quick_reference.md  ← 你的速查（含挂载模板）
6. E:\项目\自动化取证\knowledge\skills\web\baota_panel_forensics.md
7. E:\项目\自动化取证\knowledge\solved\2025pinghang\S*.yaml       ← 往届服务器解题（16 篇）
8. E:\项目\自动化取证\knowledge\solved\2025pinghang\N*.yaml       ← 往届网络解题（9 篇）

━━━ 架构地图（v4 强制） ━━━
开始前必须先写 case\server\architecture_map.md：
- 双 E01 → mmls 输出 → LVM PV/VG/LV 拓扑
- LV root (56GB, 加密) + LV data (60GB, btrfs) 各属于哪个 PV
- 已知服务清单: nginx / docker / postgresql / ngrok / TiDB
- 网络拓扑: 内网 IP 192.168.226.128, ngrok 隧道 blemish-junior-unengaged.ngrok-free.dev
没写不准答题。

━━━ 你今天的 4 步行动 ━━━

【Step 1: 复盘已答的中文丢失题（30 分钟）】
进度日志显示 Q3-Q7 等的 finding detail 中文丢失（PowerShell UTF-8 问题）。
用 Python urllib 重 POST 一遍带正确 UTF-8 的中文 finding（不要用 curl）:
```python
import urllib.request, json
data = json.dumps({...}, ensure_ascii=False).encode("utf-8")
urllib.request.urlopen(urllib.request.Request(
    "http://[HUB_IP]:8765/findings",
    data=data, headers={"Content-Type":"application/json; charset=utf-8"},
    method="POST"))
```

【Step 2: WSL 挂载 LVM（关键，解锁所有文件系统问题）】
切到 WSL Ubuntu (用户 hjsssr，密码 E:\项目\psw 第一行):
```bash
# 1. ewfmount 两个 E01
mkdir -p /mnt/e1 /mnt/e2 /mnt/server
ewfmount '/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材3-服务器/检材3-1.E01' /mnt/e1
ewfmount '/mnt/e/ffffff-JIANCAI/2026FIC团体赛/检材3-服务器/检材3-2.E01' /mnt/e2

# 2. losetup 挂载为 loop device
sudo losetup -fP /mnt/e1/ewf1
sudo losetup -fP /mnt/e2/ewf1
sudo losetup -a   # 看哪个是 /dev/loop0p1, /dev/loop1p2 等

# 3. vgscan + vgchange
sudo vgscan
sudo vgchange -ay

# 4. lvs 看到所有 LV
sudo lvs

# 5. 挂载 btrfs (LV data, 不需密码)
sudo mount -o ro /dev/volum/data /mnt/server   # btrfs

# 6. 挂载加密的 LV root
sudo cryptsetup open /dev/root/root server_root
# 密码尝试: FIC-{e404d6e66586e9460c23755afab5a872bcf78ab4}（来自 F-S003）
sudo mount -o ro /dev/mapper/server_root /mnt/server_root
```

【Step 3: 系统性解题（使用 must_scan_dirs.md）】
挂载成功后, 跳到剩余题目:
- Q2 数据卷 UUID: lsblk -f, blkid (看 btrfs UUID)
- Q3 docker 安装时间: cat /var/log/dpkg.log | grep "install docker"
- Q4 btrfs 快照子卷: btrfs subvolume list /mnt/server
- Q5 admin 后台入口: ls /mnt/server/www/wwwroot/maccms/ (找改名的 admin*.php)
- Q6/Q7: 按题面找
- Q8 第三方登录账号: psql 连 maccms 数据库 SELECT * FROM users WHERE oauth_*
- Q9 主题模板代号: cat /mnt/server/www/wwwroot/maccms/application/admin/config.php | grep template
- Q10 SM3 hash: 看哪个字段加密了 (常见: password / vip_code / api_key)
- Q11 数据库 IP: cat /mnt/server/www/wwwroot/maccms/application/database.php
- Q12-Q13 TiDB: which tiup, tidb-server --version
- Q14/Q15: 按题面找（缺答案，需要去找）
- Q16 数据卷文件系统: 选择题（btrfs/NTFS/ext4/xfs/zfs）—— A=NTFS/B=btrfs/...
- Q17 TiDB 集群组件: tiup cluster display

【Step 4: 互联网取证（独立 3 题）】
- Q1 Telegram 频道: grep -r "t.me/" /mnt/server/var/log/  + nginx access.log + 浏览器历史
- Q2: 题面缺失，需用户提供
- Q3 ngrok 域名: 已答 blemish-junior-unengaged.ngrok-free.dev (复核)

━━━ 协作铁律 ━━━

每发现一个 finding 立即 POST（Python urllib + ensure_ascii=False）:
```python
import urllib.request, json
def post(path, data):
    body = json.dumps(data, ensure_ascii=False).encode("utf-8")
    return urllib.request.urlopen(
      urllib.request.Request(f"http://[HUB_IP]:8765{path}",
        data=body,
        headers={"Content-Type":"application/json; charset=utf-8"},
        method="POST")).read().decode("utf-8")

post("/answers", {"category":"server_forensics","qid":"Q5",
     "answer":"admin1.php","analysis":"...","evidence_path":"...",
     "source_role":"server_analyst","confidence":"high"})
```

━━━ 答案验证 ━━━
答完用 lint 工具检查所有题:
```
python3 E:\项目\自动化取证\tools\answer_format_lint.py --case E:\ffffff-JIANCAI\2026FIC团体赛\case --cat server_forensics
```

━━━ 完成定义 ━━━
- LV root + LV data 都成功挂载
- 17 题服务器至少 12 题 high confidence
- 写 case\server\SOLVED_v2.md

立即开始 Step 1。
```
