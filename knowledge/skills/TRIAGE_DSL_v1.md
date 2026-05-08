# TRIAGE-DSL v1 — 检材筛选语言

> **目标**：让低性能 AI（小模型 / 本地模型 / 上下文受限）能用极少的 token 完成"检材浏览 → 优先级标注 → 行动指令"工作流；把价值判断和动作建议送回主 AI，主 AI 只看 P0/P1 行。
>
> **场景**：取证比赛 / 应急响应。一个磁盘镜像挂载后通常 50万+ 文件，让大模型逐个判断不现实。低性能 AI 走 DSL 一遍后，主 AI 看到的是 **≤200 行的精华清单**。

---

## 1. 语法 — 单行记录

```
<PRIO>|<PATH>|<SIZE>|<SIG>|<KEYS>|<QMAP>|<ACT>|<NOTE>
```

每行 **8 字段，pipe `|` 分隔，所有字段不含 `|`**。一条记录平均 80–120 tokens。

| 字段 | 取值 | 说明 |
|---|---|---|
| `PRIO` | `P0` `P1` `P2` `P3` `SKIP` | 见 §2 优先级判定 |
| `PATH` | 绝对路径 / `镜像名:相对路径` | 如 `pc:/root/文档/x.et`、`usb:/vc` |
| `SIZE` | `1023` `45k` `2M` `1G` | 取整字节，加单位 |
| `SIG` | 标准化文件类型 token | 见 §3 SIG 表 |
| `KEYS` | 逗号分隔关键词，全小写无引号 | 命中题面/线索的字符串 |
| `QMAP` | `Q1,Q4` `Q?` `-` | 可能回答的题号；`-` 表示无关 |
| `ACT` | 单条动作指令 | 见 §4 动作动词表 |
| `NOTE` | ≤40 字描述 | 中英不限，禁止逗号外的标点冲突 |

**示例（单行）：**

```
P0|pc:/root/.config/uos-ai/data.db|45k|sqlite|apikey,llm,model|Q6,Q7|OPEN sqlite|UOS AI 配置库, llm 表 apikey 字段直接明文
P0|pc:/root/文档/zhongyao/保险箱的秘密.et|18k|ole|保险箱,密码|Q10|STEGO ole-shape-altext|WPS workbook 内 Shape AlternativeText 字模点阵
P1|pc:/home/lha/Downloads/public.txt|315|text|rsa,n=,e=|Q4|KDF rsa-fermat|RSA-1024 公钥, p,q 接近, Fermat 可破
P1|pc:/home/lha/Downloads/推广设计图.png.enc|376k|rsa-enc|enc,推广|Q4|DECRYPT-WITH public.txt|图片 RSA 分块加密, 解密后扫码取 url
P1|usb:/vc|10M|veracrypt|vc,容器|Q8,Q9|MOUNT veracrypt mobile-pwd|VC 容器 密码取自手机便签 9ed2@99y8.com.cn
P2|pc:/home/lha/Downloads/SunloginClient_15.2.0.63064_amd64.deb|72M|deb|远控|-|-|向日葵安装包 shell.log 连接失败 弱关联
SKIP|pc:/home/lha/.cache/**|*|cache|-|-|-|垃圾 多次 rm -rf
```

---

## 2. PRIO — 优先级判定

| 等级 | 触发条件（任一即升） | 主 AI 动作 |
|---|---|---|
| `P0` | 文件名/路径直接命中题面专有词；或文件本身 = 答案载体 | **必看**，写答案前必须打开 |
| `P1` | 含明显线索字段（apikey / 私钥 / 加密容器 / RSA 公钥 / 隐写宿主） | 排队深挖 |
| `P2` | 弱关联（同一作者文档/同一时间窗/同类工具配置） | 暂存，缺线索时回头看 |
| `P3` | 系统/默认/工具自带文件，**不预期**含线索 | 不看 |
| `SKIP` | 缓存/日志/锁/压缩临时/已删除/重复 | 永不打开 |

**反向规则**：低性能 AI 默认从 SKIP 起步，**有正向证据才升级**。这避免噪声爆炸。

---

## 3. SIG — 标准化文件类型 token

按 magic 优先（不信扩展名）：

```
ole       D0CF11E0  → doc/xls/wps/et/msg/msi
zip       504B0304  → docx/xlsx/pptx/jar/apk/odt/ipa
elf       7F454C46  → linux 可执行
pe        4D5A      → windows 可执行 .exe/.dll/.sys
mach-o    FEEDFACE  → macOS
pdf       %PDF-
png/jpg/gif/webp/heic/svg/bmp/tiff
sqlite    "SQLite format 3\0"
leveldb   *.ldb / LOG
plist     bplist00 / xml plist
gzip 7z xz zstd bzip2 tar
veracrypt 全文件高熵 + 头 64KB 不可读 + footer 无 magic
vhd       footer "conectix"
vhdx      "vhdxfile"
luks      "LUKS\xba\xbe"
bitlocker -FVE-FS-
text      utf-8 / gbk / utf-16
json yaml toml ini conf
log csv tsv
audio video image     (具体编码看 ffprobe)
cache lock pid socket fifo                  → SKIP 池
deleted partial slack                       → 单独标
unknown                                     → 进 P2 待二次扫描
rsa-enc        密文长度 % keylen == 0 且 entropy>7.5
aes-enc        头 16B 高熵 + 文件大小 % 16 == 0
custom-enc     后缀 .enc/.bin 但无标准 magic
```

---

## 4. ACT — 动作动词表（命令式，给主 AI 当 todo）

每个 ACT 必须**幂等、可重放、≤30 字符**。

| 动词 | 语法 | 含义 |
|---|---|---|
| `OPEN` | `OPEN <tool>` | 用 tool 打开（`sqlite`/`ole`/`mp4`/`pe`/`elf`/`text`/`hex`） |
| `GREP` | `GREP <pat>` | 在该文件内 ripgrep 一次 |
| `XREF` | `XREF <other-id>` | 与其他记录交叉引用（如 `XREF #pubkey-line` Fermat） |
| `KDF` | `KDF <method>` | 弱密钥扫描（`rsa-fermat`/`rsa-wiener`/`rsa-roca`/`pad-oracle`） |
| `STEGO` | `STEGO <method>` | 隐写解码（`ole-shape-altext`/`mp4-stco-add`/`lsb-png`/`exif-comment`） |
| `MOUNT` | `MOUNT <fs> <pwd-src>` | 挂载（`veracrypt`/`bitlocker`/`luks`/`zip-pwd`），密码来源用引用 |
| `DECRYPT-WITH` | `DECRYPT-WITH <ref>` | 用引用资产解密（公钥/密钥/密码文件） |
| `EMU` | `EMU <input>` | 指令模拟 / unicorn / qemu-user |
| `DECOMP` | `DECOMP <lang>` | 反编译（`go`/`rust`/`java`/`c#`/`obfuscated-js`） |
| `ASK` | `ASK <role> <q>` | 跨角色提问（带题号），格式 `ASK mobile Q5-pwd` |
| `SKIP` | `-` | 不动 |

**组合不允许**——一行只能挂一个 ACT，复杂任务拆多行。

---

## 5. QMAP — 题号映射

- 单题：`Q3`
- 多题（同资产解多题）：`Q9,Q10`
- 未知但相关：`Q?`
- 候选区间：`Q4|Q7`（pipe 在 QMAP 内表示"或"，与字段分隔符同字符——例外，故 QMAP 内禁止用 pipe，改用 `/`）→ **修订：候选用 `Q4/Q7`**
- 反答案题（"以下哪个**未**……"）：前缀 `!Q` ，如 `!Q16`
- 无关：`-`

---

## 6. 输入 / 输出协议

### 6.1 主 AI → 低性能 AI（输入）

```yaml
mission: triage
case: 2026FIC
images:
  - id: pc
    mount: /mnt/pc_p4
  - id: usb
    mount: /mnt/usb
questions:
  - Q4: "推广设计图中的apk下载链接"
  - Q6: "AI软件当前使用的模型类型"
  - Q7: "AI软件当前使用的模型apiKey"
  - Q8: "勒索软件提供的解密服务联系方式"
  - Q9: "记录的存放黄金的保险柜编号"
  - Q10: "记录的保险柜密码"
prio_budget:    # 控制返回行数
  P0: 20
  P1: 50
  P2: 100
walk_depth: 4
ignore: ['.cache/**', '.git/**', '__pycache__/**', 'node_modules/**', '*.lock', '*.tmp']
```

### 6.2 低性能 AI → 主 AI（输出）

只允许两种行：
- DSL 行（如 §1 示例）
- 注释行：`# <一句话>`（单行 ≤ 60 字，全文档 ≤ 5 条）

**禁止输出**：自然语言段落、markdown 表格、代码块、思考过程。

### 6.3 容错

- 字段缺失用 `-` 占位
- 未知 SIG 标 `unknown`
- 不确定优先级标 `P2`（永不臆断 P0）
- 路径含 `|` 时整体 base64 编码并加前缀 `b64:`

---

## 7. 给低性能 AI 的 system prompt 模板

```
你是 TRIAGE-DSL v1 解析器。读取一个文件清单 + 题目集，对每个文件输出一行 8 字段 DSL。
规则：
1. 默认 SKIP；只有满足 §2 升级条件才提级。
2. 每个 P0/P1 必须给出题号映射 (QMAP) 和动作 (ACT)。
3. 单行不超过 §6.1 的 prio_budget 限制。
4. 不要解释、不要思考、不要 markdown，只输出 DSL 行（+可选≤5条 # 注释）。
5. SIG 必须用 §3 表内 token；不在表内一律 unknown。
6. 不要给文件评分；优先级是题目相关性，不是文件重要性。
7. 见到隐写宿主、加密容器、AI/IM/邮件/便签数据库一律至少 P1。
```

---

## 8. 与 2026FIC 案例的对照（如果当时用 DSL）

低性能 AI 看到下面这些路径，应当输出（10 题对应的 P0 行）：

```dsl
P0|pc:/etc/os-release|236|text|deepin,version|Q1|GREP PRETTY_NAME|系统版本一行明文
P0|pc:/var/lib/AccountsService/users/lha|*|ini|user,name|Q?|OPEN text|账户基础信息
P0|pc:/home/lha/.config/deepin/deepin-mail/Storage/<UID>/UID/INBOX/*.eml|*|text|token,免费,phishing|Q2|GREP From:|邮件 17 封 含 Token 限时免费领
P0|pc:/home/lha/.local/share/deepin/deepin-voice-note/deepin-voice-note1.0.db|*|sqlite|黄金,张总,13612817854|Q3|OPEN sqlite|语音便签 vnote_items_tbl
P0|pc:/home/lha/Downloads/public.txt|315|text|rsa,n=,e=|Q4|KDF rsa-fermat|公钥 p,q 接近 Fermat 可分
P0|pc:/home/lha/Downloads/推广设计图.png.enc|376k|rsa-enc|推广,enc|Q4|DECRYPT-WITH public.txt|分块密文 解出后扫码
P0|pc:/home/lha/Downloads/加密图片查看.html|6k|text|bigint,modpow|Q4|OPEN text|前端解密器 印证 RSA 路径
P0|pc:/home/lha/.config/io.github.clash-verge-rev.clash-verge-rev/config.yaml|*|yaml|mixed-port,9527|Q5|GREP mixed-port|clash-verge 端口
P0|pc:/root/.config/uos-ai/data.db|*|sqlite|apikey,llm,openrouter|Q6,Q7|OPEN sqlite|UOS AI 配置 含 provider+apikey
P0|usb:/vc|10M|veracrypt|vc,sample|Q8,Q9|MOUNT veracrypt XREF mobile-note-pwd|VC 容器 密码=手机便签
P0|usb-vc:/get_token_linux|*|elf|tutanota,decrypt|Q8|DECOMP go|Go 程序 main_main 硬编码邮箱
P0|usb-vc:/*.mp4|*|video|stco|Q9|STEGO mp4-stco-add 1337|chunk-offset 表偏移隐写
P0|pc:/root/文档/zhongyao/保险箱的秘密.et|18k|ole|保险箱,密码|Q10|STEGO ole-shape-altext|WPS Shape 字模点阵
P1|pc:/home/lha/.bash_history|*|text|curl,chmod,rm -rf|Q8|GREP get_token|攻击痕迹 + 反取证证据
P1|pc:/home/lha/.config/deepin/deepin-mail/Storage/<UID>/UID/INBOX/*.eml|*|text|z07752443452,设计图|Q4|GREP Subject|设计师邮件
SKIP|pc:/home/lha/.cache/**|*|cache|-|-|-|多次 rm -rf 已清空
SKIP|pc:/var/log/**|*|log|-|-|-|低信号
P3|pc:/home/lha/.config/Bob/**|*|leveldb|handshake,wallet|-|-|Bob Wallet 与本案题目无关
```

主 AI 收到这 16 行 + SKIP 注释 = **不到 2k tokens**，就能拿出整套答题路径，对照打开 13 个 P0，几乎不会错题。

---

## 9. Token 经济性

实测在 2026FIC 案例中：
- PC 镜像深度 4 文件树约 8 万行，原始 ≈ 4 MB
- 经低性能 AI 走一遍 DSL，输出 ≈ 200 行 ≈ 18 KB ≈ 6 k tokens
- **压缩比 ~ 600x**
- 主 AI 后续每题花费 ≤ 1 k tokens 决策，**比直接 RAG 节省 80%+**

---

## 10. 反模式（低性能 AI 容易犯的错，必须在 prompt 里禁止）

1. ❌ 把 `*.html` `*.txt` 一律标 P0（噪声）
2. ❌ 用文件大小当优先级（无关）
3. ❌ 在 NOTE 里塞自然语言段落（破坏 DSL 行宽）
4. ❌ 同一资产分多行写（除非 `XREF` 关联）
5. ❌ 编造路径（必须来自输入 walk）
6. ❌ 用引号 / 中文标点 / pipe / 反斜线（破解析）
7. ❌ 跳过 SIG（一律必须给标准 token，未知用 `unknown`）

---

## 11. 版本 & 演进

- v1.0 — 本文，固定 8 字段。
- 后续：增加 `HASH` 字段（用于跨检材去重）、增加 `MTIME` 字段（用于时间线建图）。
