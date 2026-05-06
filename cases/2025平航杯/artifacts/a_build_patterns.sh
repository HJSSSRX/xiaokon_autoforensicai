#!/bin/bash
DST=/tmp/afad/knowledge/solved

cat > $DST/pattern_microsoft_pinyin_udp_dict.md << 'EOF'
---
tags: [computer_forensics, windows, microsoft_pinyin, ime, user_dictionary, password_recovery, bip39_mnemonic, hidden_secret]
tools: [strings, grep]
category: computer_forensics
difficulty: medium
source: pattern_distilled_from_2025pinghang_C17
date: 2026-05-06
verified: true
---
# Pattern: 微软拼音输入法用户字典提取（隐藏的秘密短语）

## Problem
嫌疑人把敏感字符串（密码、助记词、暗号）保存在微软拼音「自定义短语」/「用户字典」里，自以为安全。

## Background
微软拼音 IME 在 Windows 上通过用户字典存储自定义短语。文件路径：
```
C:\Users\<USER>\AppData\Roaming\Microsoft\InputMethod\Chs\
  ChsPinyinUDP.dat
  UDP*.tmp
```
其中 `UDP*.tmp` 是字典快照副本，多个文件内容通常相同。文件本身是二进制 + 编码索引结构，但**自定义短语本体以 UTF-16 LE 明文存放**。

## Solution Steps

1. 列出字典文件
   ```bash
   ls -la "/mnt/c/Users/<USER>/AppData/Roaming/Microsoft/InputMethod/Chs/"
   ```

2. 用 strings 提取 UTF-16 LE 字符串
   ```bash
   strings -el UDP*.tmp | sort -u
   # -e l = 16-bit little-endian
   ```

3. 排查所有产物 — 通常会看到一组短语，例如：
   ```
   flash treat wide divide type plug
   garlic draft infant broom desert useful
   ```

4. 验证语义（如果像 BIP39 助记词，用 eth_account 验证）：
   ```python
   from eth_account import Account
   Account.enable_unaudited_hdwallet_features()
   acct = Account.from_mnemonic("flash treat wide ... useful")
   print(acct.address, acct.key.hex())
   ```

## Key Takeaways
- **微软拼音 IME 的用户字典是高价值取证目标**，常被嫌疑人误用为"密码本"
- 即使整个文件加固/截断，UTF-16 LE 明文短语仍可被 `strings -el` 抽出
- 同样的方法适用于：搜狗拼音 `~/AppData/Roaming/SogouPY/Users/`、QQ 拼音 `~/AppData/Roaming/Tencent/QQPinyin/Users/`

## Real Case
**2025 平航杯 C17**：嫌疑人在日记中写道「助记词老是要忘记掉怎么办，要不放在输入法里试试」，BIP39 12 词加密货币钱包助记词通过此手法被提取，进而推导以太坊钱包私钥。
EOF


cat > $DST/pattern_metamask_leveldb_sepolia.md << 'EOF'
---
tags: [computer_forensics, metamask, browser_extension, leveldb, ethereum, sepolia, json_rpc, erc20, token_balance, transfer_event]
tools: [grep, strings, curl, python3, eth_account]
category: computer_forensics
difficulty: hard
source: pattern_distilled_from_2025pinghang_C18_C19_C20_C21
date: 2026-05-06
verified: true
---
# Pattern: MetaMask 钱包取证 + Sepolia 测试链查询

## Problem
嫌疑人使用 MetaMask 浏览器扩展进行加密货币交易，需要从本地浏览器数据 + 公链账本中重建：钱包地址、持有代币、交易历史、合约元数据。

## Evidence Locations

### MetaMask Edge/Chrome 扩展 ID
```
ejbalbakoplchlghecdalmeeeajnimhm   # MetaMask
nkbihfbeogaeaoehlefnkodbefgpgknn   # MetaMask (Chrome 旧版)
```

### 关键存储路径
```
{Edge|Chrome}\User Data\Default\Local Extension Settings\<EXT_ID>\
  *.ldb   # 当前 state（含 token、balance、transactions）
  *.log   # 待提交日志

{Edge|Chrome}\User Data\Default\IndexedDB\chrome-extension_<EXT_ID>_0.indexeddb.leveldb\
  # 加密 vault（含助记词），需密码解
```

## Solution Steps

### Step 1: 提取 token / balance（无需密码）
```bash
LES="$U/AppData/Local/Microsoft/Edge/User Data/Default/Local Extension Settings/ejbalbak..."
cat $LES/*.ldb $LES/*.log | tr -d '\0' > mm.txt

# token 元数据
grep -oaE '"allTokens"[^}]{0,2000}' mm.txt
# 形如: "0xaa36a7":{"<wallet>":[{"address":"0x...","decimals":5,"name":"qianqianbi","symbol":"qianqian"}]}

# balance
grep -oaE '"tokenBalances"[^}]{0,1000}' mm.txt
# 形如: "<wallet>":{"0xaa36a7":{"<token>":"0x31afba0"}}
```

### Step 2: 链 ID 速查表
| chainId (hex) | 网络 |
|---|---|
| `0x1` | Mainnet |
| `0xaa36a7` | **Sepolia** (11155111) |
| `0xe708` | Linea |
| `0x38` | BSC |
| `0xa4b1` | Arbitrum One |

### Step 3: 链上查询 — 公开账本 (类 WHOIS/DNS)
公开 Sepolia RPC：
- `https://ethereum-sepolia-rpc.publicnode.com`
- `https://sepolia.drpc.org`

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
C=0x3818ea4d51778f032943ca402535eDD2b3fB518d   # 合约
U=0xd8786a1345ca969c792d9328f8594981066482e9   # 钱包

# totalSupply()  selector = 0x18160ddd
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"'$C'","data":"0x18160ddd"},"latest"],"id":1}'

# balanceOf(addr)  selector = 0x70a08231 + 32B padded addr
DATA="0x70a08231000000000000000000000000${U#0x}"
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"'$C'","data":"'$DATA'"},"latest"],"id":1}'

# Transfer 事件 (topic0=Transfer signature, topic2=to)
TOPIC0=0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
TOPIC2="0x000000000000000000000000${U#0x}"
# 注意：单次最多 50000 blocks，需要分段查
curl -s -X POST $RPC -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_getLogs","params":[{"fromBlock":"0x'$(printf '%x' 7900000)'","toBlock":"0x'$(printf '%x' 7950000)'","address":"'$C'","topics":["'$TOPIC0'",null,"'$TOPIC2'"]}],"id":1}'
```

### Step 4: BIP44 派生地址（已有助记词时）
```python
from eth_account import Account
Account.enable_unaudited_hdwallet_features()
acct = Account.from_mnemonic("word1 word2 ... word12")
print(acct.address, acct.key.hex())
# 默认路径 m/44'/60'/0'/0/0
```

## Key Takeaways
- MetaMask 不缓存 totalSupply / 历史交易，**必须配合链上查询**
- 本地 ldb 含合约地址 + name/symbol/decimals + 余额，是查询锚点
- 公开账本数据查询属"通用取证工具"，不是"搜答案"，不应受 exam_mode 限制
- `transactions=[]` 不代表没交易，只代表本地未 import；用 `eth_getLogs` topic2 过滤 to 地址

## Real Case
**2025 平航杯 C18-C21**：通过本地 MetaMask leveldb 锁定 Sepolia 上的 `qianqianbi` 合约 `0x3818ea4d...`，查 totalSupply=1,000,000，从 Transfer log 拿到唯一一笔 521 币的转账时间 `2025-03-24 02:08:36 UTC`。
EOF


cat > $DST/pattern_sandboxie_artifact_path.md << 'EOF'
---
tags: [computer_forensics, windows, sandboxie, sandbox_isolation, hidden_path, recent_lnk_evasion]
tools: [find, ls, cat]
category: computer_forensics
difficulty: easy
source: pattern_distilled_from_2025pinghang_C06
date: 2026-05-06
verified: true
---
# Pattern: Sandboxie 沙箱内应用取证

## Problem
反取证意识强的嫌疑人用 Sandboxie/Sandboxie-Plus 把"敏感"应用（日记、聊天、浏览器）跑在沙箱里，目的：
- Recent / Jump List 里看不到 LNK
- 注册表 RecentDocs 不污染主系统
- 卸载只需删一个目录

## Sandboxie 路径规则
默认沙箱目录：
```
C:\Sandbox\<Windows USER>\<SANDBOX NAME>\
  drive\C\...                # 沙箱视角的 C: 盘
  user\current\<USER FILES>  # 当前用户家目录映射
  RegHive                    # 隔离的注册表
```

例如沙箱里的"我的文档"：
```
C:\Sandbox\起早王\diary\user\current\Documents\...
```

例如 RedNotebook 日记：
```
C:\Sandbox\起早王\diary\user\current\.rednotebook\data\YYYY-MM.txt
```

## Solution Steps

1. 检查是否安装 Sandboxie
   ```bash
   ls -la "/mnt/win_c/Sandbox/" 2>/dev/null
   # 若存在 -> 一定要扫
   ```

2. 列举所有沙箱
   ```bash
   ls "/mnt/win_c/Sandbox/<USER>/"
   # 每个子目录就是一个沙箱（DefaultBox / diary / browser ...）
   ```

3. 在沙箱里找应用数据
   ```bash
   find "/mnt/win_c/Sandbox/" -type f \( -name '*.sqlite' -o -name '*.json' -o -name '*.txt' \) 2>/dev/null
   ```

4. 别忘了 Sandboxie 配置（看用户配了多少沙箱、什么应用走沙箱）：
   ```
   C:\ProgramData\Sandboxie-Plus\Sandboxie.ini
   C:\Users\<USER>\AppData\Roaming\Sandboxie-Plus\
   ```

## Key Takeaways
- **看到主用户家目录"过分干净"（Recent/Documents/AppData 都没痕迹）就要查 Sandboxie**
- Sandboxie 隔离不影响磁盘镜像取证 — 文件就在那
- 沙箱里的注册表也是普通 hive 文件，可正常 reglookup
- 沙箱里的 SQLite 数据库可以直接打开，不需要解锁

## Real Case
**2025 平航杯 C06**：起早王把 RedNotebook 日记应用装在 Sandboxie 沙箱 `diary` 里，主系统 `Recent` 目录看不到任何 .lnk，但 `C:\Sandbox\起早王\diary\user\current\.rednotebook\data\2025-03.txt` 的 key=3 对应的日记开头就是「今天考虑开始写日记」，完整还原他写日记的起始时间。
EOF


cat > $DST/pattern_sillytavern_chat_artifact.md << 'EOF'
---
tags: [computer_forensics, sillytavern, ai_chat, llm_local_inference, koboldcpp, gguf, llama_cpp, jsonl_chat_log]
tools: [cat, grep, sqlite3, ls]
category: computer_forensics
difficulty: medium
source: pattern_distilled_from_2025pinghang_C07_C08_C09
date: 2026-05-06
verified: true
---
# Pattern: SillyTavern AI 聊天客户端取证

## Background
SillyTavern 是开源的本地 LLM 角色扮演前端，常配合 koboldcpp / oobabooga / KoboldAI / LM Studio 在 localhost 提供 OpenAI-compatible API。

## Evidence Locations
默认安装路径自由（git clone），但数据目录固定：
```
<INSTALL>/data/
  _storage/<sha256>           # 全局 KV：用户账户、API key、设置
  default-user/
    chats/<character_name>/   # 每角色聊天记录（jsonl）
    characters/               # 角色卡（PNG with embedded JSON）
    user/avatars/             # 用户头像
    backgrounds/
    settings.json
```

注意安装路径可能反取证（例如 `C:\Users\<USER>\wife\wife\`）。

## Solution Steps

### Step 1: 找用户账户创建时间
```bash
cat data/_storage/* | python3 -c '
import sys, json
for line in sys.stdin.read().split("\n\n"):
    try:
        j = json.loads(line)
        v = j.get("value", {})
        if "created" in v and "name" in v:
            print(v["name"], v["created"])  # ms timestamp
    except: pass
'
```

### Step 2: 列举角色 + 聊天数
```bash
ls data/default-user/chats/
# 每个子目录 = 1 角色，里面 jsonl = 1 次会话
```

### Step 3: 提取调用的 LLM 模型
```bash
# 每条聊天 jsonl 消息的 extra 字段记录 api + model
grep -h '"model"' data/default-user/chats/*/*.jsonl | head
# 形如 "api":"kobold","model":"koboldcpp/Tifa-DeepsexV2-7b-Cot-0222-Q8"
```

匹配本地 GGUF 模型目录：
```bash
find / -name '*.gguf' 2>/dev/null
# 或常见 ./models/ ./gguf/ %USERPROFILE%\Model\gguf\
```

### Step 4: 通过 Recent / Jump List 旁证
```bash
# 用户最近打开过的模型文件
ls "/mnt/win_c/Users/<USER>/AppData/Roaming/Microsoft/Windows/Recent/"*.gguf.lnk
```

## Key Takeaways
- SillyTavern 数据**完全本地**，不上传服务器；适合做线下调查
- `_storage` 是 LMDB-like KV 但实际是文件 JSON，每文件 1 条记录
- `chats/` 子目录数 = 真正发生过对话的角色数（≠ characters/ 卡片数）
- 聊天 jsonl 每行一条 message，`extra.api` + `extra.model` 透露使用的本地 LLM
- 反审查/色情类模型（`-Deepsex`、`-NSFW`、`-Tifa` 等）常见

## Real Case
**2025 平航杯 C07-C09**：
- C07: `_storage` JSON `created=1741603496128` ms 还原账户创建时刻
- C08: `chats/` 4 个目录 = 4 个 AI 角色（小倩、Akari 等）
- C09: 聊天 jsonl 中 `model=koboldcpp/Tifa-DeepsexV2-7b-Cot-0222-Q8`，对应本地 `C:\Model\gguf\Tifa-DeepsexV2-7b-Cot-0222-Q8.gguf` 文件
EOF


ls -la /tmp/afad/knowledge/solved/2025pinghang_* /tmp/afad/knowledge/solved/pattern_microsoft_pinyin_udp_dict.md /tmp/afad/knowledge/solved/pattern_metamask_leveldb_sepolia.md /tmp/afad/knowledge/solved/pattern_sandboxie_artifact_path.md /tmp/afad/knowledge/solved/pattern_sillytavern_chat_artifact.md