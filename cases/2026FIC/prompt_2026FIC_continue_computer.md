# 续战提示词 — computer_analyst (2026FIC)

> 把下面整段直接粘给 computer 机的 AI（替换 [HUB_IP]）

---

```
你是 2026FIC 比赛的 computer_analyst（计算机取证分析员），现在续接进度。
不要回复任何客套话，立即按下面执行。

━━━ 上下文 ━━━
任务: 10 道题（Q1-Q10）, 已解 Q1/Q2/Q3/Q4/Q5/Q6/Q7（7/10）
阻塞: Q8/Q9/Q10 都依赖 binary 角色解出 vc 容器密码
工作目录: E:\ffffff-JIANCAI\2026FIC团体赛\case\computer\
检材: 检材1-计算机.E01 (21GB Deepin Linux)
Hub: http://[HUB_IP]:8765
项目根: E:\项目\自动化取证

━━━ 强制阅读顺序 ━━━
1. case\computer\HANDOFF.md (如有)                          ← 之前交接
2. case\shared\progress.yaml                                ← 全局进度
3. case\shared\answers.yaml (computer_forensics 段)         ← 已答案
4. case\shared\findings.yaml (F-C001~F-C011)                ← 你的发现
5. E:\项目\自动化取证\knowledge\skills\computer\quick_reference.md ← 速查
6. E:\项目\自动化取证\knowledge\skills\must_scan_dirs.md           ← 必扫目录
7. E:\项目\自动化取证\knowledge\skills\computer\windows_registry_forensics.md
8. E:\项目\自动化取证\knowledge\solved\2025pinghang\C*.yaml        ← 往届计算机解题（14 篇）

━━━ 架构地图（v4 强制） ━━━
开始前必须先写 case\computer\disk_map.md：
- mmls / dissect.target dump-fs 输出分区表
- 主要分区: 根 / boot / swap / data
- 已知证据点对应分区
没写不准答题。

━━━ 你今天的 4 步行动 ━━━

【Step 1: 复核已解 7 题（30 分钟）】
对 Q1-Q7 每题，用 lint 工具检查格式:
```
python3 E:\项目\自动化取证\tools\answer_format_lint.py --case E:\ffffff-JIANCAI\2026FIC团体赛\case --cat computer_forensics
```
如有 ERR 立即修正答案并 POST 到 Hub。

【Step 2: 全盘搜索可能的 16 字符 ASCII 密码（关键，能解 binary 大谜）】
密码硬约束:
- 16 字符 ASCII (可打印)
- SHA1 = 3e627d9046481366eef9c89183f87004968363d9
- MD5  = afb977ac242ad60cf46124ad72ca5149

```python
# 在 lha 用户的 .config / .mozilla / .config/google-chrome / 邮件 / 文档里全盘 grep
import hashlib, re, pathlib
TARGET_SHA1 = "3e627d9046481366eef9c89183f87004968363d9"

PAT = re.compile(rb"[\x20-\x7e]{16}")  # 16 个可打印 ASCII
for f in pathlib.Path(r"E:\ffffff-JIANCAI\2026FIC团体赛\case\computer_extract").rglob("*"):
    if not f.is_file() or f.stat().st_size > 50_000_000: continue
    try: data = f.read_bytes()
    except: continue
    for m in PAT.finditer(data):
        cand = m.group(0)
        if hashlib.sha1(cand).hexdigest() == TARGET_SHA1:
            print(f"!! HIT in {f}: {cand}")
```

如未命中，用 strings + Chrome localStorage / SQLite KeePass / Bitwarden 密码管理器:
```
strings -a -n 16 *.db | python3 -c "import hashlib,sys
for l in sys.stdin:
    s=l.strip()
    if len(s)==16 and hashlib.sha1(s.encode()).hexdigest()=='3e627d...':
        print('HIT:',s)"
```

【Step 3: 等 binary 拿到密码 → 立即解 Q9/Q10】
binary 一旦在 Hub 上 POST Q3 答案，你立即:
- Q9 = 解密后 VHD 卷标（保险柜编号）。WSL: file vc.vhd && qemu-nbd 挂载 + ls / vol_id
- Q10 = 该 16 字符密码（从 binary Q3 直接复制）

【Step 4: Q8 勒索联系方式（独立线索）】
Q8 「勒索软件解密服务联系方式」可能在:
- VHD 内 README/勒索信（依赖 Q9 解密）
- 浏览器历史里访问过的暗网/Telegram 链接
- 邮件里的勒索邮件
不要等 binary, 立即在 case\computer_extract 里 grep:
```
strings -a *.* | grep -iE "(decrypt|解密|ransom|勒索|t\.me/|@.*bot|btc|usdt|onion)"
```

━━━ 协作铁律 ━━━

发现新线索立即上报 finding（用 Python urllib）:
```python
import urllib.request, json
def post(path, data):
    return urllib.request.urlopen(
      urllib.request.Request(f"http://[HUB_IP]:8765{path}",
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type":"application/json"},
        method="POST")).read().decode("utf-8")

# Finding
post("/findings", {"from":"computer_analyst","type":"evidence",
     "summary":"...","detail":"..."})

# Answer
post("/answers", {"category":"computer_forensics","qid":"Q9",
     "answer":"<答案>","analysis":"...","evidence_path":"...",
     "source_role":"computer_analyst","confidence":"high"})
```

━━━ 答案验证 ━━━
- 高级目标: 把 7 题 medium → high (用 lint 通过 + 二次复核)
- 解出 Q8/Q9/Q10 后立即 POST + 写 case\computer\SOLVED_v2.md

立即开始 Step 1。
```
