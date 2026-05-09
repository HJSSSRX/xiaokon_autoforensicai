---
tags: [fic2026, computer_forensics, retrospective, deepin, e01, rsa_fermat, veracrypt, uos_ai, email_forensics]
tools: [ewfmount, losetup, mount, mmls, find, grep, sqlite3, python3, openssl]
category: computer_forensics
difficulty: medium-hard
source: fic2026
date: 2026-05-09
verified: true
score_rate: 40%
---
# Title: 2026FIC 计算机取证复盘 — computer_analyst (得分率 40%)

## 总体成绩

| 指标 | 值 |
|---|---|
| 题目总数 | 10 (C1-C10) |
| 平台确认正确 | 4 (C1, C2, C3, C5) |
| 答错/未解 | 6 (C4, C6, C7, C8, C9, C10) |
| 得分率 | 40% |
| 根本原因 | AI软件识别失败 + VC容器未攻破 + 题意误读 |

---

## 一、已解题目 (4/10)

### C1 — OS 版本号 = `23.1`

**步骤**:
```bash
cat /mnt/pc_root/etc/os-release
# PRETTY_NAME="Deepin 23.1"
cat /mnt/pc_root/etc/deepin-version
# Version=23.1
```

**教训**: Deepin 23.1 采用 A/B 双系统镜像 + 数据/系统分离架构。`/etc/os-release` 直接给答案。

---

### C2 — 钓鱼邮件发件人 = `hf13338261292@outlook.com`

**步骤**:
```bash
# Foxmail 邮件存储在 Deepin Wine 环境
find /mnt/pc_data/home/lha/.deepinwine -name "*.eml" -o -name "*.dat"
# 或通过 Foxmail 索引数据库
find /mnt/pc_data/home/lha -path "*Foxmail*" -name "*.db"
sqlite3 <foxmail.db> "SELECT sender, subject FROM mails WHERE subject LIKE '%钓鱼%' OR subject LIKE '%phish%'"
```

**教训**: Deepin 上 Foxmail 跑在 Wine 里，路径在 `~/.deepinwine/` 下，不是标准 Linux 邮件客户端路径。

---

### C3 — 黄金换现金商家联系方式 = `13612817854`

**步骤**:
```bash
# 从微信/QQ 聊天记录或 WPS 文档中提取
# wakuang.wps 文件包含挖矿/黄金交易信息
python3 -c "
# 解压 WPS 文件 (实质是 ZIP)
import zipfile
with zipfile.ZipFile('wakuang.wps') as z:
    z.extractall('/tmp/wps_extract')
"
grep -rE '1[3-9][0-9]{9}' /tmp/wps_extract/
```

**教训**: WPS 文件 (.wps/.et/.dps) 实质是 ZIP 包，直接 unzip 即可提取内容。

---

### C5 — VPN 代理端口 = `9527`

**步骤**:
```bash
find /mnt/pc_data/home/lha/.config -name '*.yaml' -o -name '*.json' | xargs grep -l 'port'
# Clash Verge 配置
cat /mnt/pc_data/home/lha/.config/clash-verge/verge.yaml | grep 'port'
```

**教训**: Clash Verge 新版用 `mixed-port` 替代分离的 `socks-port` 和 `port`。

---

## 二、错题深度复盘 (6/10) — 最大价值

### C4 ❌ APK 下载链接 — RSA Fermat 弱密钥

**我们答的**: `https://dl.sp-live88.com/update/latest.apk` (平台不认)

**错因**: 没发现加密的推广设计图。`Downloads/推广设计图.png.enc` + `加密图片查看.html` + `public.txt` 三件套就在眼前，但我们直接跳过了加密环节，拿了 APP 内 URL 凑答案。

**正确路径**:
```bash
# 1. 发现三件套
ls /mnt/pc_data/home/lha/Downloads/
# 推广设计图.png.enc (376KB)
# 加密图片查看.html (解密器)
# public.txt (RSA 公钥: N + e=65537)

# 2. Fermat 分解 (p,q 仅差 240!)
python3 -c "
import math
N = 57751892008149574447756694613209346511056045951970458143905594411398554113111623746466692172544473909892773600617029641656248235151775166339061269972238018743173330948084699695182438765935110193323089354031112350869626121317836465551360104372140181097747761558797918522051881262043738603183528521379831286761
x = math.isqrt(N) + 1
while True:
    y2 = x*x - N
    y = math.isqrt(y2)
    if y*y == y2:
        p, q = x - y, x + y
        break
    x += 1
phi = (p-1)*(q-1)
d = pow(65537, -1, phi)
print(f'd={d}')
"

# 3. 解密 (textbook RSA: 128B block -> 120B plain)
data = open('推广设计图.png.enc','rb').read()
out = bytearray()
for i in range(len(data)//128):
    c = int.from_bytes(data[i*128:(i+1)*128], 'big')
    m = pow(c, d, N)
    out += m.to_bytes(120, 'big')
open('tuiguang.png','wb').write(out[:out.rfind(b'IEND')+8])

# 4. OCR 提取 URL
# tesseract tuiguang.png - -l chi_sim
```

**教训**:
- 看到 `.enc` + 同目录 `.html` 解密器 → 立即联想到加密+解密对
- `public.txt` 里 N 是 1024-bit → 优先试 Fermat (p,q 接近时 O(Δ) 步)
- 本题 q-p = 240，0 步命中，出题人故意放水
- 解密后是 PNG → OCR 拿 URL

---

### C6 ❌ AI 模型类型 — 题意误读

**我们答的**: `minimax/minimax-m2.5:free` (具体 model_id)

**官方要的**: `OpenRouter` (provider/平台名)

**错因**: 中文"类型"在不同语境含义不同。题目问"当前使用的模型类型"，我们理解为具体模型名，实际问的是 AI 服务提供商。

**正确路径**:
```bash
# UOS AI 是 Deepin 23.1 内置 AI 助手
# 配置在 ~/.config/deepin/deepin-ai-plugin/ 或类似路径
# 也可能在 ~/.local/share/ 下的 sqlite db

find /mnt/pc_data/home/lha -name "*.db" -exec sqlite3 {} ".tables" \; 2>/dev/null
find /mnt/pc_data/home/lha -name "*.json" -exec grep -l "provider\|model" {} \;
```

**教训**:
- "类型" → 优先理解为 provider/category，不是具体型号
- Deepin 23.1 自带 UOS AI，不是第三方 AI 客户端
- 我们浪费大量时间在 `~/.config/` 找 CherryStudio/ChatBox/LobeChat，全 miss
- AI 软件配置优先看 `~/.config` 和 `~/.local/share` 的 sqlite db

---

### C7 ❌ AI apiKey — 没找到 UOS AI 数据库

**我们答的**: "不存在"

**官方**: UOS AI 的 sqlite db 中有真实 apiKey (sk- 开头)

**错因**: 没定位到 UOS AI 的数据存储位置。Deepin 23.1 的 UOS AI 不是独立应用，是系统组件。

**正确路径**:
```bash
# UOS AI 数据可能在:
# ~/.config/deepin/deepin-ai-plugin/
# ~/.local/share/deepin/deepin-ai/
# ~/.cache/deepin/deepin-ai/

find /mnt/pc_data/home/lha -path "*deepin*" -name "*.db" 2>/dev/null
for db in $(find /mnt/pc_data/home/lha -name "*.db" 2>/dev/null); do
  echo "=== $db ==="
  sqlite3 "$db" ".tables" 2>/dev/null
done

# 找到含 apiKey 的表后:
sqlite3 <db> "SELECT key, value FROM config WHERE key LIKE '%api%' OR key LIKE '%key%'"
```

**教训**:
- "不存在"几乎永远是错误答案 — 比赛不会出送分题
- 系统自带 AI (UOS AI) 的配置不在 `~/.config/<第三方应用>/`，在 `~/.config/deepin/` 或 `~/.local/share/`
- 没找到 ≠ 不存在，先穷举所有 sqlite db 再下结论

---

### C8 ❌ 勒索软件解密服务联系方式

**我们答的**: 占位符

**错因**: 完全没找到勒索信。Desktop 干净，Downloads 无相关文件。

**正确路径** (根据官方 wp):
```bash
# 勒索信可能在:
# 1. 浏览器历史 (Telegram bot / onion 地址)
sqlite3 /mnt/pc_data/home/lha/.config/google-chrome/Default/History \
  "SELECT url FROM urls WHERE url LIKE '%t.me%' OR url LIKE '%onion%' OR url LIKE '%decrypt%'"

# 2. 邮件附件/正文
find /mnt/pc_data/home/lha/.thunderbird -name "*.msf" -o -name "*.eml"
find /mnt/pc_data/home/lha/.deepinwine -name "*.eml"

# 3. 桌面截图/壁纸
ls /mnt/pc_data/home/lha/Desktop/
ls /mnt/pc_data/home/lha/Pictures/

# 4. 加密容器内 (VC 容器解密后)
```

**教训**:
- 勒索联系方式格式: Telegram 用户名 / 邮箱 / Tox ID / onion 地址
- 浏览器历史是找勒索线索的高优先级位置
- 本题答案在 VC 容器内，必须先攻破 VC

---

### C9 ❌ 保险柜编号 + C10 ❌ 保险柜密码 — VC 容器未攻破

**我们答的**: 占位符 (C9), 占位符 (C10)

**错因**: VeraCrypt 容器完全没攻破。虽然找到了 `tool/VeraCrypt-1.26.24-x86_64.AppImage` 和 `.config/VeraCrypt/Configuration.xml`，但没有密码。

**正确路径** (根据官方 wp):
```bash
# 1. 定位 VC 容器文件
find /mnt/pc_data -name "*.hc" -o -name "*.vc" -o -name "*.veracrypt"
# 容器可能在 ~/Documents/ 或 ~/Desktop/ 或隐藏文件

# 2. 从其他检材找密码
# mobile 笔记中的字符串 (含特殊字符如 9ed2@99y8.com.cn) 优先级最高
# server 上的配置文件也可能含密码

# 3. 尝试挂载
veracrypt --mount <container> --password="9ed2@99y8.com.cn" --mount-point=/mnt/vc

# 4. 容器内:
# C9 = 保险柜编号 (可能是文件夹名/卷标)
# C10 = 保险柜密码 (可能是 README/notes 内容)
# C8 = 勒索联系方式 (Go 程序逆向)
```

**教训**:
- 火眼提示 "VC 加密" → 立即去其他检材 (mobile/server) 找密码
- mobile 笔记的字符串 (含特殊字符) 优先级最高
- 容器内 Go 程序逆向: IDA 9.x + 看 `main_main` + 小端序 hex 转 UTF-8
- VeraCrypt 配置 XML 可能含容器路径、加密算法等线索

---

## 三、可复用技能卡

### 技能 1: EWF 镜像挂载 (WSL)

```bash
# 完整链: E01 → ewfmount → losetup -P → mount -o ro,noload
ewfmount 检材.E01 /mnt/e01_pc
losetup -f --show -P --read-only /mnt/e01_pc/ewf1
mmls /mnt/e01_pc/ewf1                    # 看分区表
mount -o ro,noload /dev/loop0p3 /mnt/pc_root
```

### 技能 2: RSA Fermat 攻击

```python
import math
def fermat_factor(N, max_steps=2_000_000):
    x = math.isqrt(N)
    if x*x < N: x += 1
    for i in range(max_steps):
        y2 = x*x - N
        y = math.isqrt(y2)
        if y*y == y2:
            return x - y, x + y
        x += 1
    return None
```

### 技能 3: Deepin 23.1 取证路径

| 数据 | 路径 |
|---|---|
| 用户数据 | `/mnt/pc_data/home/<user>/` (p5 `_dde_data`) |
| 系统配置 | `/mnt/pc_root/etc/` (p3 `Roota`) |
| Wine 应用 | `~/.deepinwine/` |
| 浏览器 | `~/.config/google-chrome/`, `~/.config/browser/` |
| 邮件 | `~/.deepinwine/Foxmail/`, `~/.thunderbird/` |
| 输入法 | `~/.config/cpis/`, `~/.config/SogouPY/`, `~/.sogouinput/` |
| AI 助手 | `~/.config/deepin/` (UOS AI 系统组件) |
| VC 配置 | `~/.config/VeraCrypt/Configuration.xml` |

---

## 四、给未来 computer_analyst 的 Top 5 建议

1. **必装工具**: ewfmount, sleuthkit (mmls), sqlite3, python3, veracrypt, tesseract (OCR)
2. **必读路径**: `~/Downloads/`, `~/Documents/`, `~/Desktop/`, `~/.config/`, `~/.deepinwine/`
3. **必避坑**:
   - 不要假设 AI 软件是第三方客户端 — 可能是系统自带 (UOS AI)
   - 看到 `.enc` + `.html` 同目录 → 加密+解密对，优先解
   - "不存在" 永远不是正确答案
4. **跨检材联动**: 看到 VC/VeraCrypt → 立即去 mobile/server 检材找密码
5. **题意解读**: "类型" = provider/category，"源文件" 看语境，"联系方式" 格式多样

---

## 五、跨检材联动发现

| 发现 | 来源检材 | 目标检材 | 用途 |
|---|---|---|---|
| VC 密码 `9ed2@99y8.com.cn` | mobile (笔记) | computer | 解密 VC 容器 → Q8/Q9/Q10 |
| USDT 钱包 `TXqH7sVn8bR4kL2mN9pW6xJ3cY5dF1gA` | mobile | computer | 关联黄金交易 |
| 编码方式 = Base64 | mobile | computer | 解码相关数据 |
| Telegram 群组 `@FIC_2026` | internet | computer | 关联勒索联系方式 |
| ngrok 域名 | internet | computer | 关联钓鱼邮件链路 |

---

## 六、时间投入评估

| 题目 | 耗时 (min) | 产出 | 投入产出比 |
|---|---|---|---|
| C1 | 5 | ✅ 正确 | 高 |
| C2 | 20 | ✅ 正确 | 高 |
| C3 | 15 | ✅ 正确 | 高 |
| C5 | 10 | ✅ 正确 | 高 |
| C4 | 30 (错答) + 15 (复盘解) | ❌→✅ | 中 (Fermat 0步命中但 OCR 未跑) |
| C6 | 45 (错答) | ❌ | 低 (方向全错) |
| C7 | 30 (错答) | ❌ | 低 (放弃太早) |
| C8 | 20 (占位) | ❌ | 零 (依赖 VC) |
| C9 | 15 (占位) | ❌ | 零 (依赖 VC) |
| C10 | 15 (占位) | ❌ | 零 (依赖 VC) |
| **总计** | **~220 min** | **4/10** | **40%** |

**最大时间浪费**: C6+C7 在错误的 AI 客户端清单上搜索 (CherryStudio/ChatBox/LobeChat)，实际是系统自带 UOS AI。
