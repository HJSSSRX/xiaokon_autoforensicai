# 给 computer_analyst 的戳醒文本

> **使用方法**：完整复制下面 `===` 之间的内容，粘到远程机 1（computer）的 IDE chat 窗口

===

你是 `computer_analyst`。你已经停工 16.5 小时了。先拉一下最新状态再继续。

## Step 1: 立即同步项目（v3.1 新版本，已修中文 UTF-8 bug）

```powershell
cd "e:\项目\自动化取证"
git pull origin main
```

## Step 2: 检查 inbox

```powershell
$Hub = "http://127.0.0.1:8765"   # 如果你走 cloudflared 隧道，改成隧道地址
Invoke-RestMethod "$Hub/ping"
Invoke-RestMethod "$Hub/questions?to=computer_analyst" | Where-Object { -not $_.answer } |
    Select-Object id, from, question | Format-List
```

你应该看到 4 个未回复的紧急 question（全部来自 binary）：
- **QQ005**（17.1h 前）：vc 密码可能在浏览器/KeePass/.bash_history
- **QQ007**（15.6h 前）：vc 是 RC4-VHD（不是 VeraCrypt），更新前次假设
- **QQ009**（15.6h 前）：完整密码 dump 清单（10 个具体位置）
- **QQ010**（15.3h 前）：完整 RC4 验证脚本，直接抄到本地用大字典跑

## Step 3: 优先做 QQ009 + QQ010（同一件事）— vc 16 字符密码暴破

binary 已经确认：
- vc = RC4-encrypted VHD
- 密码 = 16 字符可打印 ASCII
- SHA1 = `3e627d9046481366eef9c89183f87004968363d9`
- MD5 = `afb977ac242ad60cf46124ad72ca5149`

binary 已穷尽 ZxcvbnData 30K + 智能候选 5921 全失败。**需要从 PC 各个角落 dump 16 字符候选**。

按 QQ009 的 10 个位置全跑一遍：

```powershell
$ImageRoot = "你的 PC 镜像挂载根目录"  # e.g. "E:\ffffff-JIANCAI\2026FIC团体赛\image_pc"
$lha_home = "$ImageRoot\home\lha"

# 1. 浏览器保存的密码（Login Data sqlite）
$chrome_login = "$lha_home\.config\google-chrome\Default\Login Data"
$ff_logins = Get-ChildItem -Recurse "$lha_home\.mozilla\firefox" -Filter "logins.json" -ErrorAction SilentlyContinue
$ff_signons = Get-ChildItem -Recurse "$lha_home\.mozilla\firefox" -Filter "signons.sqlite" -ErrorAction SilentlyContinue

# 拷出 Login Data 副本（防止 sqlite 锁），用 sqlite3 dump
Copy-Item $chrome_login "C:\temp\chrome_login.db" -ErrorAction SilentlyContinue
sqlite3 "C:\temp\chrome_login.db" "SELECT origin_url, username_value, length(password_value) FROM logins;"
# 注意：password_value 是 DPAPI 加密的，需要 master key. 但 username_value 可能是明文的「我的密码」备注

# 2. Firefox logins.json
Get-Content $ff_logins.FullName -ErrorAction SilentlyContinue | ConvertFrom-Json | Select-Object hostname, encryptedUsername, encryptedPassword

# 3. KeePass / Bitwarden / 1Password 数据库文件
Get-ChildItem -Recurse "$lha_home" -Include "*.kdbx", "*.keychain", "*.bitwarden", "*.1password" -ErrorAction SilentlyContinue
```

```powershell
# 4. /home/lha 下所有可能含密码的文本（深度 4 限制时间）
Get-ChildItem -Recurse -Depth 4 -File "$lha_home\Documents", "$lha_home\Desktop", "$lha_home\Downloads" `
    -Include "*.txt", "*.md", "*.docx", "*.xlsx", "*.csv", "*password*", "*pwd*", "*密码*", "*备份*" -ErrorAction SilentlyContinue |
    Select-Object FullName, Length

# 5. .bash_history 完整
Get-Content "$lha_home\.bash_history" -ErrorAction SilentlyContinue
Get-Content "$lha_home\.zsh_history" -ErrorAction SilentlyContinue

# 6. Telegram / 微信 聊天缓存
Get-ChildItem -Recurse "$lha_home\.config\TelegramDesktop\tdata" -ErrorAction SilentlyContinue
Get-ChildItem -Recurse "$lha_home\Documents\WeChat Files" -ErrorAction SilentlyContinue
```

```powershell
# 7. 全盘 grep 16 字符 ASCII 候选（不局限文本文件）
$rg_path = "rg.exe"   # ripgrep, 如果没装用 strings + grep
& $rg_path -a --no-binary -o '\b[\x21-\x7E]{16}\b' $lha_home 2>$null |
    Select-Object -ExpandProperty Line -Unique |
    Where-Object { $_ -notmatch '^[0-9a-f]{16}$' -and $_ -notmatch '^[A-Za-z0-9+/=]{16}$' } |
    Out-File "C:\temp\candidates_16char.txt" -Encoding utf8

"候选数: $((Get-Content C:\temp\candidates_16char.txt).Count)"
```

## Step 4: 用 binary 提供的 RC4 脚本本地验证

QQ010 给了完整脚本，把 vc 文件拷到 PC 本地，跑：

```powershell
# 先拉一个 vc 副本到本地（如果你这台机器没有）
# 主设计师机器路径: E:\ffffff-JIANCAI\2026FIC团体赛\case\binary\vc
# 远程机请通过 SMB / scp / hub 文件下发拿到 vc

# 假设 vc 在本地 C:\temp\vc
$vc_path = "C:\temp\vc"

# 写 SHA1+RC4 验证脚本（精简版）
@'
import hashlib, sys
TARGET_SHA1 = "3e627d9046481366eef9c89183f87004968363d9"
PT_VARIANTS = {
    "NTFS":  bytes.fromhex("EB5290") + b"NTFS    ",
    "FAT32": bytes.fromhex("EB5890") + b"MSWIN4.1",
    "FAT32_2": bytes.fromhex("EB5890") + b"mkfs.fat",
    "exFAT": bytes.fromhex("EB7690") + b"EXFAT   ",
}
VC = open(sys.argv[1], "rb").read()
exp_ks = {n: bytes(VC[i] ^ pt[i] for i in range(len(pt))) for n, pt in PT_VARIANTS.items()}

def rc4_ks(key, n=11):
    S = list(range(256)); j = 0
    for i in range(256):
        j = (j + S[i] + key[i % len(key)]) & 0xFF
        S[i], S[j] = S[j], S[i]
    i = j = 0; out = bytearray(n)
    for k in range(n):
        i = (i + 1) & 0xFF; j = (j + S[i]) & 0xFF
        S[i], S[j] = S[j], S[i]
        out[k] = S[(S[i] + S[j]) & 0xFF]
    return bytes(out)

with open(sys.argv[2], encoding="utf-8", errors="ignore") as f:
    for line in f:
        p = line.strip().encode("utf-8", "ignore")
        if len(p) != 16 or not all(0x21 <= b <= 0x7E for b in p):
            continue
        if hashlib.sha1(p).hexdigest() != TARGET_SHA1:
            continue
        ks = rc4_ks(p, 11)
        for fs, exp in exp_ks.items():
            if ks == exp:
                print(f"*** HIT [{fs}]: {p!r}")
                sys.exit(0)
        print(f"SHA1_only: {p!r}")
print("done.")
'@ | Out-File -Encoding utf8 "C:\temp\rc4_check.py"

python C:\temp\rc4_check.py C:\temp\vc C:\temp\candidates_16char.txt
```

## Step 5: POST 结果（**Python urllib，禁用 PowerShell ConvertTo-Json**）

```python
import urllib.request, json, hashlib

# 计数候选
candidates = [l.strip() for l in open(r'C:\temp\candidates_16char.txt', encoding='utf-8') if l.strip()]
candidates_16 = [c for c in candidates if len(c) == 16]

# SHA1 hit?
hit = next((c for c in candidates_16
            if hashlib.sha1(c.encode()).hexdigest() == '3e627d9046481366eef9c89183f87004968363d9'),
           None)

if hit:
    body = {
        "id": "F-C013",
        "from": "computer_analyst",
        "type": "evidence",
        "summary": f"vc 16字符密码 = '{hit}' (SHA1命中)",
        "details": "在 PC 镜像 <具体位置> 找到候选，SHA1 + RC4 双验证通过",
        "confidence": "high",
        "related_to": ["binary_analyst", "stego_crypto"],
        "source": "computer_image/<填具体位置>",
    }
    endpoint = "http://127.0.0.1:8765/findings"
else:
    body = {
        "from": "computer_analyst",
        "to": "binary_analyst",
        "question": (
            f"QQ009/QQ010 回复：PC 全盘 dump 完成。"
            f"16字符 ASCII 候选 {len(candidates_16)} 个，SHA1 全 miss。"
            f"前 50 个候选: {candidates_16[:50]}"
        ),
    }
    endpoint = "http://127.0.0.1:8765/questions"

data = json.dumps(body, ensure_ascii=False).encode("utf-8")
req = urllib.request.Request(endpoint,
    data=data,
    headers={"Content-Type": "application/json; charset=utf-8"},
    method="POST")
urllib.request.urlopen(req)
```

## Step 6: 更新 progress

```python
import urllib.request, json, datetime
body = {
    "status": "active" if "hit" in dir() and hit else "blocked_on_dict",
    "current_task": "PC 全盘密码 dump 完成 / 已回 QQ009-010" if hit else "需大字典 (SecLists/weakpass)",
    "updated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
}
data = json.dumps(body, ensure_ascii=False).encode("utf-8")
req = urllib.request.Request("http://127.0.0.1:8765/progress/computer_analyst",
    data=data,
    headers={"Content-Type": "application/json; charset=utf-8"},
    method="POST")
urllib.request.urlopen(req)
```

完成后请汇报：(1) 候选数量、(2) 是否 SHA1 命中、(3) 已回复哪几个 QQ。

===
