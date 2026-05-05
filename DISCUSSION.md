# AutoForensicAI v2 — 核心问题讨论

> 不是照搬参考，而是独立思考：什么才是适合我们场景的最佳方案。

---

## 一、CLI vs MCP — 老实说，CLI 赢了

### 1.1 数据说话

来自两篇独立 benchmark（2025/2026）：

| 指标 | CLI | MCP |
|---|---|---|
| **Token 开销** | ~200 tokens/次调用 | ~55,000 tokens 仅工具定义 |
| **差距** | — | **35 倍** 浪费在"管道"而非"思考" |
| **任务完成率** | 100% | 100%（相同） |
| **Token 效率分 (TES)** | 202 | 152（CLI 高 33%） |
| **AI 是否已知** | ✅ 训练数据包含海量 CLI 用法 | ❌ 每个 MCP schema 都是首次见 |

### 1.2 为什么对我们特别重要

我们的核心场景是 **弱模型 + 离线**：

- **弱模型 context 小**：7B 模型可能只有 8K-32K context。一个 MCP server 的 schema 就能吃掉一半。CLI 几乎零开销。
- **模型已经会用 CLI**：即使是 7B 的 Qwen，也在训练数据里见过 `nmap -sV`、`vol3 windows.pslist`、`strings`。但它没见过 `volatility_mcp.analyze_processes({"dump": "..."})` 这种自定义 schema。
- **离线无法装 MCP**：很多比赛环境不允许装额外服务。但 `nmap`、`volatility` 这些 CLI 工具可以提前装好。
- **可组合**：`tshark -r capture.pcap -T fields -e http.host | sort -u` — 一行搞定 MCP 需要三次调用的事。

### 1.3 结论

**CLI 为主，MCP 为辅（可选增强）。**

- 系统核心 100% 基于 CLI + 文件系统
- 如果用户恰好用支持 MCP 的平台（Claude Desktop/Cursor/Windsurf），可以加 MCP 获得更好体验
- 但 **没有 MCP 也能完整运行**

### 1.4 那之前列的 MCP 工具还要不要？

**要，但定位变了**：

| 之前的定位 | 现在的定位 |
|---|---|
| MCP 是核心调用方式 | MCP 是可选的"舒适层" |
| 没 MCP 就用不了 | CLI 是基线，MCP 是增强 |
| 每个工具都要 MCP 封装 | 只为真正没有 CLI 的东西做 MCP（如 Burp Suite） |

**真正需要 MCP 的**只有 Burp Suite（它本身是 GUI，没有好用的 CLI）和 Autopsy（同理）。其他工具 nmap/volatility/sqlmap/ffuf 全都有成熟 CLI。

---

## 二、启动流程 —— "小空自己动"

### 2.1 你描述的流程（我理解的）

```
用户: "小空自己动"
  ↓
Main Agent（设计者/总指挥）启动
  ↓
用户告诉 Main: "我要做什么"（训练/比赛/灌知识/教育）
  ↓
Main 分析情况:
  - 比赛? → 分析题目类型 → 决定需要几个角色
  - 训练? → 检查知识库缺口 → 制定训练计划
  - 灌知识? → 确认输入源 → 制定提取策略
  ↓
Main 输出:
  1. 创建本次任务的工作目录和协作结构
  2. 给出每个专业角色的提示词（用户复制到新窗口）
  3. 开始协调工作
```

### 2.2 实际实现 — 这里是关键讨论

**问题**：Main Agent 到底是什么？

不是一个单独的程序。**它就是你当前窗口的 AI**，但读取了一个特定的系统提示。

具体来说：

```
# 你在 Windsurf 里说 "小空自己动"
# 等价于让当前 AI 读取 MAIN_PROMPT.md，进入 Main 模式
```

**跨平台实现**：

| 平台 | Main 怎么启动 | 专业角色怎么开 |
|---|---|---|
| **Windsurf** | 用 workflow（`.windsurf/workflows/xiaokong.md`） | 用户开新 tab，粘贴 Main 生成的提示词 |
| **Cursor** | 用 rules（`.cursor/rules/main.mdc`） | 用户开新 Cursor 窗口 + 角色 rules |
| **Claude Code** | 用 agent teams（`claude --team`） | 自动 spawn teammates |
| **通用终端** | `python main.py --mode competition` | 用户开新终端窗口 |

**注意**：Claude Code 有原生的 Agent Teams 机制，可以自动 spawn 多个窗口（tmux session）并互相通信。但我们不能依赖它，因为用户可能用 Windsurf/Cursor/甚至 Ollama 终端。

### 2.3 所以方案是

**Main 生成的不是代码，而是提示词 + 目录结构。**

Main 的输出是这样的：

```markdown
## 任务分析结果

本次比赛共 3 个检材：1 台电脑（Windows 10）、1 部手机（Android）、1 个服务器（Linux）

### 建议开设 4 个角色窗口：

---

#### 窗口 1: 电脑分析师
复制以下内容到新窗口的第一条消息：

> 你是 AutoForensicAI 的电脑取证分析师。
> 工作目录: E:\案件\2026-05-05\computer\
> 检材: Windows 10 磁盘镜像 (computer.E01)
> 你的任务: 分析该镜像，找出所有与案件相关的数字证据。
> 
> 可用知识库: @knowledge/skills/computer_analyst/
> 协作目录: E:\案件\2026-05-05\shared\
> 进度文件: E:\案件\2026-05-05\shared\computer_progress.yaml
> 
> 工作流程:
> 1. 先用 Arsenal Image Mounter 挂载镜像
> 2. 运行 KAPE 收集快速证据
> 3. 检查注册表、事件日志、浏览器历史
> 4. 每发现一个重要线索，写入 shared/ 目录
> 5. 定期检查 shared/ 看其他角色是否有交叉线索

---

#### 窗口 2: 手机分析师
...

#### 窗口 3: 服务器分析师
...

### 已创建的目录结构：
E:\案件\2026-05-05\
├── computer\          ← 电脑分析工作区
├── mobile\            ← 手机分析工作区
├── server\            ← 服务器分析工作区
├── shared\            ← 协作交换区
│   ├── timeline.yaml  ← 共享时间线
│   ├── findings.yaml  ← 重要发现
│   └── questions.yaml ← 待确认问题
└── report\            ← 最终报告
```

### 2.4 为什么这样设计

1. **人也能用**：即使没有 AI，一个人类分析师看到这个提示词也知道该干什么
2. **模型无关**：提示词是纯文本，任何模型都能理解
3. **平台无关**：不依赖任何特定 IDE 的 API
4. **协作靠文件**：`shared/` 目录是唯一的通信通道，谁都能读写

---

## 三、协作机制 — 文件就够了

### 3.1 不需要 MessageBus、不需要 MCP、不需要数据库

之前参考 ctf-agent 的 MessageBus 和 pentest-ai-agents 的 SQLite，这些都是**程序化多 Agent 系统**的解法。但我们的场景是**多窗口**，每个窗口是独立的 AI 会话。

**它们之间唯一通用的通信方式就是文件系统。**

### 3.2 协作文件格式

```yaml
# shared/findings.yaml — 任何角色发现重要线索就追加
- id: F001
  time: "2026-05-05 14:23"
  from: computer_analyst
  type: evidence
  summary: "发现 PowerShell 远控脚本，连接 192.168.1.100:4444"
  detail: "路径: C:\Users\admin\AppData\Local\Temp\update.ps1"
  related_to: [server]  # 提示服务器分析师关注这个 IP

- id: F002
  time: "2026-05-05 14:35"
  from: mobile_analyst
  type: evidence
  summary: "微信聊天记录提到 '今晚 8 点上传数据'"
  related_to: [computer, server]
```

```yaml
# shared/questions.yaml — 跨角色提问
- id: Q001
  from: server_analyst
  to: computer_analyst
  question: "电脑上是否有 SSH 密钥？我在服务器日志里看到 SSH 登录"
  status: pending  # pending → answered

- id: Q002
  from: computer_analyst
  to: server_analyst
  answer_to: Q001
  answer: "是的，在 C:\\Users\\admin\\.ssh\\id_rsa，已复制到 shared/artifacts/"
  status: answered
```

### 3.3 Main 的持续职责

Main 不只是开局分配任务。它要**定期检查** shared/ 目录：

- 汇总各角色进度
- 发现交叉线索时提醒相关角色
- 调整策略（如发现某个方向没价值，建议停止）
- 最终汇总成报告

实际操作中，这意味着用户回到 Main 窗口，说"检查一下进度"，Main 就读 shared/ 目录并给出建议。

---

## 四、四种模式的具体差异

| | 比赛 | 训练 | 灌知识 | 教育 |
|---|---|---|---|---|
| **Main 做什么** | 分析检材→分工 | 选题→分配→验证 | 确认输入源→提取 | 出题→讲解→验证 |
| **需要几个角色** | 按检材定（2-5 个） | 1 个即可（做题） | 1 个（提取器） | 2 个（出题+答题） |
| **用什么模型** | 最强可用模型 | 强模型（生成 WriteUp） | 中等（提取够用） | 弱模型（模拟学员） |
| **时间压力** | 高（限时） | 低（可慢慢来） | 无 | 无 |
| **协作目录** | 必须 | 不需要 | 不需要 | 可选 |
| **知识库** | 只读（查询） | 读写（新增 WriteUp） | 只写（灌入） | 只读（出题） |

### 4.1 比赛模式详细流程

```
"小空自己动" → Main 启动
  ↓
用户: "比赛模式，题目材料在 E:\比赛\2026国赛\"
  ↓
Main 扫描目录:
  - 发现 computer.E01 (15GB, Windows 镜像)
  - 发现 mobile.tar (Android 备份)
  - 发现 server_memory.raw (内存镜像)
  - 发现 capture.pcap (流量包)
  ↓
Main 输出:
  1. 创建工作目录结构
  2. 生成 4 个角色提示词（电脑/手机/服务器/网络）
  3. 预加载对应的 skill 文件到各角色 prompt
  4. 创建 shared/ 协作目录
  ↓
用户: 开 4 个窗口，分别粘贴提示词，开始工作
  ↓
各角色独立分析，发现线索写入 shared/
  ↓
用户不定期回 Main 窗口: "进度如何？"
Main 读取 shared/ → 汇总 → 提建议 → 调整策略
```

### 4.2 训练模式详细流程

```
"小空自己动" → Main 启动
  ↓
用户: "训练模式，做 CTFShow 的电子取证题"
  ↓
Main:
  1. 检查知识库当前状态（哪些领域弱）
  2. 建议优先训练的题目类型
  3. 生成解题角色的提示词（包含相关 skill）
  ↓
用户: 开新窗口，粘贴提示词，开始做题
  ↓
做完一题 → 角色自动生成 WriteUp → 写入知识库
  ↓
用户回 Main 窗口: "做完了"
Main: 审核 WriteUp 质量，更新训练统计
```

### 4.3 灌知识模式

```
"小空自己动" → Main 启动
  ↓
用户: "灌知识模式，学习这几个 URL: ..."
  ↓
Main: 在当前窗口直接执行（不需要多角色）
  - 提取内容
  - 结构化为知识卡
  - 去重检查
  - 写入知识库
  - 更新索引
```

---

## 五、反思：之前方案哪些过度设计了

| 之前设计 | 问题 | 更好的方案 |
|---|---|---|
| MessageBus（内存共享） | 需要写代码，平台依赖 | YAML 文件就行 |
| SQLite 持久化 | 对于多窗口协作来说太重了 | 文件系统 + 简单的 YAML |
| Coordinator → Swarm → Solver 三层 | 那是自动化竞赛系统，不是人机协作 | Main + 角色窗口就够了 |
| 22 个 MCP server | 吃 token，维护复杂 | CLI 工具 + 2-3 个真正需要的 MCP |
| 自动 spawn 窗口 | 依赖特定平台 API | Main 生成提示词，人来开窗口 |
| SOLVE-IT 编号体系 | 学术气太重，实用性有限 | 简单标签 + 领域分类足够 |

### 但这些参考不是白看的

- **ctf-skills 的 SKILL.md 格式**：真有用，直接采用
- **D-CIPHER 的 "每个任务全新对话" 思路**：通过多窗口自然实现了
- **ctf-agent 的 "失败后交叉注入其他人的发现"**：通过 shared/findings.yaml 实现
- **pentest-ai-agents 的角色化 prompt**：Main 生成的提示词就是这个

---

## 六、工具链的重新定位

### 6.1 CLI 优先的工具清单

不再按 MCP 分类，而是按**角色需要什么 CLI 工具**分类：

**电脑分析师需要的 CLI**:
```
vol3, strings, exiftool, regripper, chainsaw, hayabusa, 
fls, icat, mmls, foremost, binwalk
```

**手机分析师需要的 CLI**:
```
adb, aleapp, ileapp, mvt, strings, sqlite3
```

**网络分析师需要的 CLI**:
```
tshark, tcpdump, nmap, strings, zeek
```

**Web 渗透需要的 CLI**:
```
nmap, sqlmap, ffuf, gobuster, nuclei, nikto, hydra, curl
```

**逆向/密码需要的 CLI**:
```
ghidra (headless), radare2, strings, john, hashcat, z3
```

### 6.2 只有两个东西真正需要 MCP

- **Burp Suite**：纯 GUI，没有好的 CLI 替代品（BurpMCP 有价值）
- **SOLVE-IT 知识库**：作为结构化知识的查询接口（MCP 比手动翻文件方便）

其他全都用 CLI。

### 6.3 工具安装方案

不需要复杂的 `toolchain.yaml` 注册系统。一个 shell 脚本就够了：

```powershell
# install-tools.ps1 -Role computer_analyst
# 根据角色安装对应的 CLI 工具，检查是否已装
```

---

## 七、待讨论的问题

1. **"小空自己动" 的触发方式**：是 Windsurf workflow？是一个 .md 文件？还是一个 Python 脚本？
   - 我倾向于：一个 `MAIN_PROMPT.md` 文件 + 各平台的薄适配层

2. **角色提示词的格式**：纯 Markdown？还是 YAML frontmatter + Markdown？
   - 我倾向于：纯 Markdown（最通用，任何平台都能粘贴）

3. **知识库搜索**：SQLite FTS5 是否值得引入？还是简单的文件名 + grep 够用？
   - 训练阶段可以先用 grep，规模大了再考虑 FTS

4. **多窗口 vs 单窗口**：每次都开多个窗口是否太麻烦？
   - 训练/灌知识模式可以单窗口完成
   - 只有比赛模式才真正需要多窗口

5. **训练自动化的程度**：是全自动（后台跑）还是半自动（人看着）？
   - 我倾向于半自动：人选题 → AI 做 → 人审核 WriteUp
