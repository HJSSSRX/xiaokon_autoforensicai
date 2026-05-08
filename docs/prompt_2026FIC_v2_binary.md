# 续战提示词 v2 — binary_analyst (2026FIC)

> 把下面整段直接粘给 binary 机的 AI（替换 [HUB_IP]）

---

```
你是 2026FIC 比赛的 binary_analyst（二进制取证分析员），现在续接进度。
不要回复任何客套话，立即按下面执行。

━━━ 当前真实状态（来自 DIDCTF 平台） ━━━
[平台已确认]
- Q1 ✅ MD5 = 764789dd9c095d74b6b258cf0f7568b2
- Q2 ✅ 编译日期 = 2026-04-17

[剩余 3 题, 全卡在 Q3 密码]
- Q3 ❌ 密码 (16 字符 ASCII, 答案格式: abcdefghABCDEFGH)
- Q4 ❌ 解密后文件后缀 (我们之前答 ".vhd" 错了, 应该是 "vhd" 不带点)
- Q5 ❌ 收款金额 (依赖解密 vc 后查交易记录)

━━━ 强制阅读顺序 ━━━
1. case\binary\HANDOFF.md                                       ← 你之前的交接
2. case\shared\todo.yaml (binary_forensics 段)                  ← 待解题目
3. case\shared\diff_report.md                                   ← 答案对比
4. case\shared\findings.yaml (F-B001~F-B007)                    ← 你的发现
5. E:\项目\自动化取证\knowledge\skills\binary\quick_reference.md
6. E:\项目\自动化取证\knowledge\skills\weak_crypto_kit.md

━━━ 已确认的硬约束 ━━━
- vc 是 RC4 加密的 VHD（已通过 magic 'conectix' 验证）
- 密码 P 是 16 个可打印 ASCII 字符
- SHA1(P) = 3e627d9046481366eef9c89183f87004968363d9
- MD5(P)  = afb977ac242ad60cf46124ad72ca5149
- 已穷尽: ZxcvbnData(30K) + 8+8 padded(5921) + 智能字典 146 + 全盘 25705 字典 + 10 种变形 = 28 万次 — 全失败

━━━ 重大新线索（来自题目文件） ━━━
题目页面给出"挂载密码": FIC-{e404d6e66586e9460c23755afab5a872bcf78ab4}
这个 38 字符串不是 vc 的 16 字符密码，但内层 e404d6e6...87ab4 是某个 SHA1 哈希。
可能是 server 加密分区的密码，但也可能是 vc 密码的某种变换。

【新尝试】立即验证以下假设:
```python
import hashlib
candidates = [
    "e404d6e66586e9460c23755afab5a872bcf78ab4",   # 全 40 字符 SHA1 hex (40>16, 不行)
    "e404d6e66586e946",                            # 前 16
    "0c23755afab5a872",                            # 中段 16
    "FIC-e404d6e66586e",                           # 用FIC-前缀+13字符
    "fic-{e404d6e66586",                           # 全形式截 16
    "FIC2026e404d6e6",                             # 拼接
    "FICe404d6e66586e",                            # 15字符? 不
]
target_sha1 = "3e627d9046481366eef9c89183f87004968363d9"
for c in candidates:
    if len(c) == 16 and hashlib.sha1(c.encode()).hexdigest() == target_sha1:
        print(f"!! HIT: {c}")
```
[80% 不会命中，但花 1 分钟试一下]

━━━ 你今天的 3 步行动 ━━━

【Step 1: 哈希在线查询（5 分钟）】
- crackstation.net 贴 MD5: afb977ac242ad60cf46124ad72ca5149
- hashes.com  贴 SHA1: 3e627d9046481366eef9c89183f87004968363d9
- md5decrypt.net 同上

【Step 2: 大字典暴破（如 Step 1 失败）】
切到 WSL Ubuntu (用户 hjsssr，密码 E:\项目\psw 第一行):
```bash
sudo apt install -y hashcat
cd /mnt/e/项目
# 下载 SecLists Top 1M (内含 16 字符长密码)
wget -q https://github.com/danielmiessler/SecLists/raw/master/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt
hashcat -m 0 afb977ac242ad60cf46124ad72ca5149 10-million-password-list-top-1000000.txt --force

# 如未中, 拼接 8+8 (你之前已穷尽 5921, 但只是 rockyou 子集; 现在试 top10k+top10k = 1亿)
wget -q https://github.com/danielmiessler/SecLists/raw/master/Passwords/Common-Credentials/10k-most-common.txt
hashcat -m 0 -a 1 afb977ac242ad60cf46124ad72ca5149 10k-most-common.txt 10k-most-common.txt --force

# 题面 / 案件主题相关组合(色情网站, sp-live88, 黄金, 保险柜, 李安弘):
echo -e "splive88adminuser\nlianhongli2026!!\nfic2026sphotgolden\n..." > theme.txt
hashcat -m 0 afb977ac242ad60cf46124ad72ca5149 theme.txt --force
```

【Step 3: Frida hook (终极方案)】
如果暴破 1 小时未中, 改用动态分析:
```bash
# Windows 上启动 SampleVC.exe + Frida hook strncmp 调用
frida -l hook_password.js -f SampleVC.exe
```
hook_password.js 拦截 strncmp 第二参数 (用户输入), 转储所有候选。
但需要 SampleVC.exe 还在等输入 - 已知它崩溃, 需逆向 strncmp 调用前的代码看密码从哪读。
case\binary\fcn.140002200 函数有完整 disasm, 重新逐行读。

━━━ 拿到密码后立刻完成 Q3-Q5 ━━━
```python
# decrypt_vc.py
import hashlib
P = b"<密码>"
assert hashlib.sha1(P).hexdigest() == "3e627d9046481366eef9c89183f87004968363d9"

from Crypto.Cipher import ARC4
data = open(r"E:\ffffff-JIANCAI\2026FIC团体赛\case\binary\vc", "rb").read()
plain = ARC4.new(P).decrypt(data)
open(r"E:\ffffff-JIANCAI\2026FIC团体赛\case\binary\decrypted.vhd", "wb").write(plain)

# Q4: 后缀 = vhd (不带点!)
# Q5: 用 qemu-nbd 或 7z 打开 decrypted.vhd, 找交易记录文件 (Excel/CSV/SQLite/txt), SUM(收款金额)
```

━━━ 协作铁律（用 Python urllib, 不用 curl） ━━━
```python
import urllib.request, json
def post(path, data):
    body = json.dumps(data, ensure_ascii=False).encode("utf-8")
    return urllib.request.urlopen(
      urllib.request.Request(f"http://[HUB_IP]:8765{path}",
        data=body,
        headers={"Content-Type":"application/json; charset=utf-8"},
        method="POST")).read().decode("utf-8")

# 解出立即报: 答案
post("/answers", {"category":"binary_forensics","qid":"Q3",
     "answer":"<16字符密码>","analysis":"hashcat + ... 命中",
     "evidence_path":"case\\binary\\decrypt_vc.py",
     "source_role":"binary_analyst","confidence":"high",
     "verification_status":"verified"})

# 进展报: finding
post("/findings", {"from":"binary_analyst","type":"evidence",
     "summary":"已尝试 SecLists Top10k 字典, 未命中",
     "detail":"hashcat -m 0 -a 0 ... 用时 3 秒, 跳到下一个字典"})
```

━━━ 答案格式硬要求 ━━━
- Q4 = vhd (不带点!)
- Q5 = 数字, 格式如 1.00 或 1234.56 (一位或两位小数)

跑完用 lint 复核:
```
python3 E:\项目\自动化取证\tools\answer_format_lint.py --case E:\ffffff-JIANCAI\2026FIC团体赛\case --cat binary_forensics
```

━━━ 完成定义 ━━━
- Q3/Q4/Q5 全部 high confidence + Hub 上报成功 + lint 通过
- decrypted.vhd 成功生成, footer = 'conectix'
- 写 case\binary\SOLVED_v2.md 记录密码来源 + 暴破方法 + 时间

立即开始 Step 1。
```
