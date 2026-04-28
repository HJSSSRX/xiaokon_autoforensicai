# AI Agent 启动手册

> 你是一个在 Windsurf IDE 中运行的 Claude AI agent。本文件告诉你如何快速进入电子取证解题状态。

---

## 第一步：读大脑

按顺序读以下 5 个文件（**不要跳过**）：

```
1. AI_BRAIN/README.md            → 总索引，告诉你整个体系怎么运作
2. AI_BRAIN/persona.md           → 你的工作风格定义
3. AI_BRAIN/output_contract.md   → 答案必须包含的 5 个字段
4. AI_BRAIN/tool_inventory.md    → 工具在哪、怎么用
5. AI_BRAIN/session_handoff.md   → 上一次 AI 做到哪了
```

读完后，你应该能回答：
- 我的输出格式是什么？（5 字段）
- 我有哪些可用工具？
- 上次做到哪了？

## 第二步：确认模式

问用户你今天要用哪种模式：

| 模式 | 场景 | 你的行为 |
|------|------|---------|
| **SOLO** | 熟悉题型，要最快 | 少问多跑，自主决策 |
| **COOP** | 题目复杂 | 先 triage 分桶再推进 |
| **TEAM** | 多机协作 | Git 同步 + facts/inbox |
| **REVIEW** | 赛后复盘 | 不赶时间，重在总结 |

默认用 SOLO。

## 第三步：读题目

```
cases/<比赛名>/questions.md     → 全部题目
cases/<比赛名>/TASKS.md         → 任务跟踪（哪些做了、哪些没做）
```

## 第四步：开始解题

### 通用解题流程

```
1. 读题 → 明确"要找什么"
2. 查 AI_BRAIN/solved_patterns/ → 有没有同类套路
3. 定位证据（sqlite3 / grep / find / strings）
4. 提取答案
5. 验证（可复现命令）
6. 写 WP（5 字段格式）
```

### 速通题特征（先做这些）
- 操作系统版本 → `cat /etc/os-release`
- 文件哈希 → `md5sum <file>`
- 数据库简单查询 → `sqlite3 db ".tables"` → `SELECT ...`
- 配置文件读取 → `cat <config>` + `grep`

### 硬骨头特征（后做这些）
- 需要反编译 APK → jadx
- 需要逆向 PE → radare2
- 需要解密加密 DB → sqlcipher + APK 反编译找 key
- 需要跨检材关联 → 先做单检材题，积累 facts

## 第五步：输出规范

**每道题必须包含 5 个字段**（缺一不可）：

```markdown
## Q<NN> — <简称>

> <题目原文，一字不差>

**答案**：`<值>`
**置信度**：高/中/低

### 解析
（识别 → 提取 → 分析 → 验证，含可复现命令）

### 不作弊声明
- 数据来源：<检材路径>
- 工具列表：<用了什么>
- 未访问外部网络
```

## 关键禁令

- ❌ **不修改** `questions.xlsx`（原始只读）
- ❌ **不写入** `evidence/` 目录
- ❌ **不假装有答案**（没做出来写 "未解 + 原因"）
- ❌ **不下新工具前先问用户**
- ✅ **卡 30 分钟主动跳题**
- ✅ **每 5 题产出 wp_batches/ 批次文件**

## 踩坑预警

1. **PowerShell + WSL**: 复杂 bash **写成 .sh 文件再执行**，不要内联
2. **sudo**: WSL 里可能没有 sudo 密码，用 `cases/.wsl_pw` 或避免 sudo
3. **大文件搜索**: 永远加 `-maxdepth 5` 或 `timeout 30`
4. **中文路径**: WSL 里用 `/mnt/e/项目/...`，注意编码

## 已知套路库

查看 `AI_BRAIN/solved_patterns/` 目录，当前包含：

1. **spammimic 隐写解码** — HTTP POST 到 spammimic.com
2. **微信 DB 解密** — SQLCipher + IMEI/UIN 派生 key
3. **内存 dump 分析** — Volatility3 工作流
4. **磁盘镜像挂载** — E01/dd/vmdk 挂载流程
5. **恶意软件静态分析** — strings + r2 + .NET 反编译
6. **AES+XOR 密码校验** — PE 逆向定位 S-box → 反推明文
7. **WPS .et 隐藏字段** — ZIP 内 XML 的 descr 属性
8. **deepin-mail 邮件挖掘** — LevelDB + eml 解析

---

*读完本文件后，对用户说："已加载 AI_BRAIN，准备就绪。请给指令。"*
