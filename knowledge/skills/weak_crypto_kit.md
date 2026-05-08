# 弱密钥 / 弱口令套件

> **作用**：拿到密文 / 公钥 / hash 后，**强制走一遍弱密钥扫描**再考虑暴破。CTF 设计本就要求选手"算"出私钥，绝大部分公钥可破。
> **使用**：与 `TRIAGE_DSL_v1.md` 的 `KDF <method>` 动作对应。

---

## §1 RSA 弱密钥（必跑流程）

公钥 `(n, e)` 到手 → 强制按下表顺序跑：

| # | 攻击 | 触发条件 | 工具 | 工时 |
|---|---|---|---|---|
| 1 | **Fermat 分解** | p, q 接近（差 < 2^(k/4)） | 自写 10 行 isqrt 循环 | 秒级 |
| 2 | **小素数试除** | n 含小素数因子 | sympy.factorint / sage factor | 秒级 |
| 3 | **Pollard's rho** | 一般小因子 | sympy.factorint / yafu | 几秒 |
| 4 | **Wiener** | e 异常大或 d < n^(1/4) | RsaCtfTool / pycryptodome | 秒级 |
| 5 | **Boneh-Durfee** | d < n^0.292 | RsaCtfTool | 几秒 |
| 6 | **共模攻击** (Common Modulus) | 同 n 不同 e 各加密同 m | 自写 5 行 gcd | 秒级 |
| 7 | **小 e 广播** (Hastad) | e=3 且 m^3 < n（无 padding） | 三次方根 | 秒级 |
| 8 | **小 e + 部分 m 已知** (Coppersmith) | e=3 且部分 m 泄漏 | sage Coppersmith | 几分钟 |
| 9 | **Franklin-Reiter** | 同 n 同 e，m 之间有线性关系 | sage | 几分钟 |
| 10 | **ROCA** (CVE-2017-15361) | n 来自 Infineon 智能卡 | roca-detect | 秒级（仅检测） |
| 11 | **factordb 在线查询** | 任何 n | http://factordb.com | 秒级 |
| 12 | **n 的 LSB 模式** | (n+1)/2 是平方 | 自写 | 秒级 |

### Fermat 自写模板（10 行）

```python
from math import isqrt
n = ...      # 来自 public.txt
e = 65537
a = isqrt(n) + 1
while True:
    b = isqrt(a*a - n)
    if b*b == a*a - n:
        p, q = a-b, a+b
        break
    a += 1
d = pow(e, -1, (p-1)*(q-1))
print(d)
```

适用：**2026FIC Q4** 即此模式。

### RsaCtfTool 一行覆盖

```bash
RsaCtfTool.py --publickey public.pem --uncipherfile cipher.bin --decrypt out.bin
# 自动跑 fermat / wiener / smallq / commonfactor / factordb / ...
```

---

## §2 AES / 对称加密弱口令

| 触发 | 攻击 | 工具 |
|---|---|---|
| 短密码 / 用户记忆密码 | 字典 + rockyou.txt | hashcat / john |
| 自定义算法 (xor / 简单变换) | 反编译看 KDF | ghidra / ida + Z3 |
| ECB 模式 | 块重复观察 | 自写 |
| CBC + 已知 IV / 0 IV | 选择密文攻击 | padding oracle |
| 密钥派生 = 密码本身或简单 hash | 先穷举弱密钥候选 | 自写 |

### 弱口令字典优先级

```
1. rockyou.txt (14M 通用密码)
2. 用户专属字典 (用户名 / 邮箱 / 生日 / 电话 / 公司)  ← cupp.py 生成
3. 同案件已发现的密码 (跨检材复用，2026FIC vc 密码就在手机便签)
4. 案件主题词 (黄金 / 矿机 / 网站名 / 域名)
5. 数字组合 (生日变换 / 6位8位)
6. 常见格式 (xxx@yyy.com / xxx_yyy / xxxYYY)
7. CrackStation 在线 (大彩虹表)
```

---

## §3 Hash 反查 / 暴破

| Hash 类型 | 在线查询 | 本地暴破 |
|---|---|---|
| MD5 | hashes.com / nitrxgen / md5decrypt.net / cmd5.com | hashcat -m 0 |
| SHA1 | 同上 | hashcat -m 100 |
| SHA256 | crackstation.net | hashcat -m 1400 |
| NTLM | hashes.com | hashcat -m 1000 + rockyou |
| bcrypt | 一律本地 | hashcat -m 3200 (慢) |
| sha512crypt | 一律本地 | hashcat -m 1800 |
| Office 加密 | office2john + hashcat | hashcat -m 9400/9500/9600 |
| ZIP 加密 | zip2john | hashcat -m 17200/17225 |
| RAR3/5 | rar2john | hashcat -m 12500/13000 |
| PDF | pdf2john | hashcat -m 10500/10700 |

### 多 hash 联立约束

如**同一密码**有多个 hash 约束（MD5 + SHA1）：
- **不要分别暴破**——单 hash 暴破要 2^N，但碰撞概率随 hash 数指数下降
- **正确做法**：先 SHA1（更快/更短摘要），命中候选后 MD5 复核
- 如果两个 hash 在线查询都 0 命中 → 几乎确定是**定制密码**，去其他检材找

---

## §4 已知格式弱密码

某些密码格式被广泛用作示例 / 默认值，**优先纳入字典**：

```
admin / admin123 / password / Password / Password123
123456 / 12345678 / qwerty / abc123
P@ssw0rd / Passw0rd! / Welcome1
test / test123 / demo
root / toor
<域名>@<年份> 如 example.com@2026
<域名缩写> + 数字 + 特殊字符
1qaz2wsx / 1q2w3e4r / qwer1234
```

**2026FIC vc 容器密码** `9ed2@99y8.com.cn` 即"看似随机但有结构"（@ 间隔 + .com.cn 后缀），属于"**域名变体口令**"模式。

---

## §5 跨检材密码复用（最重要）

**经验法则**：同一用户的密码**至少 30% 概率复用**。任何检材里发现的密码都应：

1. 立刻标记为候选密码
2. 反向验证所有其他检材的加密容器
3. 包括变体（大小写、加数字尾、+ 年份、+ 特殊字符）

例如本案：手机便签 `9ed2@99y8.com.cn` → 立即试 PC vc 容器、压缩包、Office 文档、所有 hash。

### 候选密码典型来源

```
sticky notes / 便签 / Memos
SMS / 短信 / 聊天记录
邮件草稿 / 邮件正文
浏览器自动填充 / Login Data
KeePass / Bitwarden / 1Password 本地缓存
.bash_history (echo / curl 含密码)
配置文件 .env / config.yaml / docker-compose.yml
代码注释 / readme
照片相册（截图密码本）
```

---

## §6 一键脚本骨架

```python
# weak_crypto_scan.py - 公钥到手立刻跑
import sys
from sympy import factorint, isprime
from math import isqrt, gcd

def fermat(n, max_iter=10000):
    a = isqrt(n) + 1
    for _ in range(max_iter):
        b2 = a*a - n
        b = isqrt(b2)
        if b*b == b2:
            return a-b, a+b
        a += 1
    return None

def small_primes(n):
    f = factorint(n, limit=10**6)
    return f if len(f) > 1 else None

def factordb_query(n):
    import urllib.request, json
    url = f"http://factordb.com/api?query={n}"
    return json.loads(urllib.request.urlopen(url, timeout=10).read())

def wiener(n, e):
    # convergents of e/n
    ...

# main: try all in order, stop on success
```

---

## §7 反模式提醒

- ❌ 看到大整数就放弃 — 永远先跑 Fermat / factordb（30 秒成本）
- ❌ "私钥不在文件里" 就报告失败 — CTF 设计就要算出来
- ❌ 直接 hashcat rockyou 跑几小时 — 应该先查在线 rainbow 库（10 秒）
- ❌ 单 hash 暴破不结合多约束 — 同密码多 hash 时，先短 hash 过滤再长 hash 复核
- ❌ 不试跨检材密码 — **30% 概率复用是法则**
- ❌ 把"自定义加密"等同于"高强度" — 自定义往往用 xor/简单算术，反编译比暴破快
