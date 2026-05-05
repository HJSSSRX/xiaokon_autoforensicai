# AutoForensicAI v2 — 总体设计方案

> 基于对 GitHub 上 CTF/取证自动化方案的调研，结合用户需求，从零设计的 AI 自动化取证系统。

---

## 一、调研发现：现有方案的关键经验

### 1. D-CIPHER (NYU) — 多 Agent 协作的标杆

**架构**：Planner + 多个 Executor + Auto-prompter

- **Auto-prompter**：先探索环境（读文件、执行二进制、访问服务），生成针对当前题目的动态 prompt（比硬编码模板有效得多）
- **Planner**：接收 prompt 后制定计划，分步委派任务给 Executor，只看摘要不看细节（节省 context）
- **Executor**：每个任务一个全新 Executor，独立对话历史，专注单一任务后返回摘要
- **关键成果**：比单 Agent 方案解题率高 40-80%，成本反而低 2-10 倍（任务分解减少了无效推理）
- **教训**：Auto-prompter 偶尔失败时退回硬编码 prompt；Executor 超时则返回警告

**对我们的启示**：
- 多 Agent 分工确实有效，且降低对单个模型能力的要求
- 每个 Executor 用全新对话 = 弱模型也能 focus
- Planner 只需看摘要 = 大幅降低 context 需求

### 2. ctf-skills (ljagiello) — Agent 技能库的最佳实践

**特点**：334 star，兼容 Claude Code / Codex CLI / Gemini CLI / OpenCode 等多种 Agent

- 按领域分为独立 skill 文件：`ctf-web/`, `ctf-forensics/`, `ctf-crypto/`, `ctf-pwn/`, `ctf-rev/`, `ctf-misc/`
- 每个 skill 内部按子话题进一步拆分：`windows.md`, `network.md`, `disk-and-memory.md`, `steganography.md`, `linux-forensics.md`, `signals-and-hardware.md`
- 每项技术都是"一句话速查 + 详见 xx.md"的结构，非常适合索引
- 格式遵循 Agent Skills 规范（SKILL.md 描述元数据），跨 Agent 兼容

**对我们的启示**：
- 知识按领域→子领域分文件，每个文件自包含
- "一句话摘要 + 详细文档引用" 的双层结构非常适合 RAG 和弱模型
- SKILL.md 元数据格式值得采用

### 3. SOLVE-IT — 电子取证知识体系的 MITRE ATT&CK

**特点**：专门为数字取证设计的知识库框架，学术论文支持

- 编号体系：`T1001`, `T1002`... 技术；`W1001`, `W1002`... 弱点；`M1001`... 缓解措施
- 已有 MCP server 实现（solve_it_mcp），可直接让 LLM 查询
- 结构化的技术-弱点-缓解措施三元组

**对我们的启示**：
- 电子取证已有学术级分类体系，不需要自己从零发明
- 可以直接采用/扩展 SOLVE-IT 的分类做我们的标签体系

### 4. verialabs/ctf-agent — 并行竞速

**特点**：多个模型并行解同一题，竞速取最快正确答案

- BSidesSF 2026 CTF 52/52 满分夺冠
- 支持 Claude + Codex 等多后端同时跑
- JSON-RPC 协议通信

**对我们的启示**：
- 多模型并行竞速在实战中极其有效
- 弱模型多路并行 + 投票 = 可以接近强模型单路效果

### 5. pentest-ai-agents (0xSteph) — 角色化子 Agent

**特点**：35 个专业化子 Agent，每个有独立的 Markdown 提示词文件

- 每个子 Agent 专注一个领域（侦察、漏洞分析、报告、STIG 审计等）
- 通过 Markdown 文件定义角色和能力
- 任何支持 Agent 的工具都可以加载这些 Markdown

### 6. hack-skills (yaklang) — 全栈安全知识库

**特点**：覆盖 web、API、权限提升、AD 攻击、移动安全、二进制、逆向、密码学、区块链、AI安全等

- 每个领域都有独立的 SKILL.md
- 强调"先判断当前阶段（侦察/验证/提权/链构建），再选择技术"

---

## 二、与你原始需求的交叉验证

| 你的需求 | 现有方案怎么做的 | 我们的策略 |
|---|---|---|
| 模型无关 | ctf-skills 兼容 5+ Agent；D-CIPHER 测试了 5 种 LLM | 知识库纯 Markdown，接口标准化 |
| 离线优先 | 无人专门做过 | **我们的核心差异化**，必须从第一天设计 |
| 多 Agent 分工 | D-CIPHER 的 Planner-Executor 是最成熟方案 | 采用并增强为取证场景定制版 |
| 知识库索引 | ctf-skills 用纯文本；SOLVE-IT 有 MCP | 混合方案：标签索引 + 可选 RAG |
| 协作共享 | ctf-skills 通过 Git 分发 | Git 共享 + 隐私分层 |
| 并行竞速 | ctf-agent 多模型竞速 | 采用，尤其适合弱模型场景 |
| 角色化 prompt | pentest-ai-agents 35 个角色文件 | 采用，定制取证专用角色 |
| 外部知识学习 | 无人做过（都靠手动） | URL→标准化入库管道（我们的创新） |
| 进度追踪 | 无成熟方案 | 自建 WriteUp 状态机 + 进度仪表板 |

---

## 三、系统架构设计

```
AutoForensicAI/
├── DESIGN.md                  ← 本文件
├── README.md                  ← 快速入门
├── VERSION                    ← 版本号
├── PROGRESS.md                ← 整体进度追踪
│
├── config/                    ← 全局配置
│   ├── models.yaml            ← 模型配置（本地/远程/API key）
│   ├── modes.yaml             ← 模式定义（训练/比赛/测试）
│   └── platform.yaml          ← 平台配置（Windows/Linux）
│
├── strategies/                ← 策略文件（控制 AI 行为）
│   ├── training.md            ← 训练模式策略
│   ├── competition_online.md  ← 线上赛策略
│   ├── competition_offline.md ← 线下赛策略
│   ├── testing.md             ← 测试模式策略（含反作弊规则）
│   └── custom/                ← 用户自定义策略
│
├── agents/                    ← 多 Agent 角色定义
│   ├── main/                  ← 总指挥（Coordinator）
│   │   ├── AGENT.md           ← 角色定义 + 系统提示词
│   │   └── skills/            ← 总指挥专属技能
│   │       ├── case_analysis.md    ← 案件分析与分工
│   │       ├── progress_track.md   ← 进度追踪
│   │       └── result_merge.md     ← 结果汇总
│   │
│   ├── mobile/                ← 手机取证分析师
│   │   ├── AGENT.md
│   │   └── skills/
│   │       ├── android.md
│   │       ├── ios.md
│   │       └── app_analysis.md
│   │
│   ├── computer/              ← 电脑取证分析师
│   │   ├── AGENT.md
│   │   └── skills/
│   │       ├── windows.md
│   │       ├── linux.md
│   │       ├── macos.md
│   │       └── registry.md
│   │
│   ├── server/                ← 服务器取证分析师
│   │   ├── AGENT.md
│   │   └── skills/
│   │       ├── web_server.md
│   │       ├── database.md
│   │       └── log_analysis.md
│   │
│   ├── network/               ← 网络流量分析师
│   │   ├── AGENT.md
│   │   └── skills/
│   │       ├── pcap.md
│   │       ├── protocol.md
│   │       └── ids.md
│   │
│   ├── memory/                ← 内存取证分析师
│   │   ├── AGENT.md
│   │   └── skills/
│   │       ├── volatility.md
│   │       ├── process.md
│   │       └── malware.md
│   │
│   ├── crypto/                ← 密码与加解密分析师
│   │   ├── AGENT.md
│   │   └── skills/
│   │
│   └── data/                  ← 数据恢复与分析师
│       ├── AGENT.md
│       └── skills/
│           ├── disk_recovery.md
│           ├── file_carving.md
│           └── steganography.md
│
├── knowledge/                 ← 知识库（核心资产）
│   ├── taxonomy/              ← 分类体系（基于 SOLVE-IT 扩展）
│   │   ├── techniques.yaml    ← 技术分类 T0001...
│   │   ├── weaknesses.yaml    ← 常见弱点 W0001...
│   │   └── tools.yaml         ← 工具索引
│   │
│   ├── writeups/              ← 解题记录
│   │   ├── _schema.yaml       ← WriteUp 数据格式定义
│   │   ├── _index.yaml        ← 全局索引（自动生成）
│   │   ├── 2024-FIC/          ← 按比赛组织
│   │   │   ├── meta.yaml      ← 比赛元数据
│   │   │   ├── q01.yaml       ← 单题记录
│   │   │   ├── q02.yaml
│   │   │   └── ...
│   │   └── 2025-xxx/
│   │
│   ├── reference/             ← 参考资料（从外部学习的）
│   │   ├── _sources.yaml      ← 来源注册表
│   │   ├── articles/          ← 文章类
│   │   ├── tools_guides/      ← 工具教程类
│   │   └── case_studies/      ← 案例研究类
│   │
│   └── skills/                ← 通用技能库（来自 ctf-skills 等）
│       ├── forensics/         ← 取证技能
│       │   ├── windows.md
│       │   ├── linux.md
│       │   ├── network.md
│       │   ├── disk-and-memory.md
│       │   ├── steganography.md
│       │   ├── mobile.md
│       │   └── signals-and-hardware.md
│       ├── crypto/
│       ├── web/
│       └── misc/
│
├── toolchain/                 ← 工具链管理
│   ├── registry.yaml          ← 工具注册表
│   ├── install/
│   │   ├── bootstrap.ps1      ← Windows 一键安装
│   │   ├── bootstrap.sh       ← Linux 一键安装
│   │   └── check_conflicts.py ← 冲突检测
│   └── configs/               ← 各工具的配置文件
│
├── coordination/              ← 多 Agent 协调机制
│   ├── protocol.md            ← 协调协议说明
│   ├── shared/                ← 共享工作区（Agent 间交换信息）
│   │   ├── tasks/             ← 任务分配
│   │   │   ├── pending/       ← 待处理
│   │   │   ├── active/        ← 进行中
│   │   │   └── done/          ← 已完成
│   │   ├── findings/          ← 发现（线索、证据、答案）
│   │   ├── messages/          ← Agent 间消息
│   │   └── status.yaml        ← 全局状态
│   └── templates/             ← 消息模板
│
├── index/                     ← 索引系统
│   ├── tags/                  ← 标签索引（零算力）
│   ├── fulltext/              ← 全文索引
│   └── vectors/               ← 向量索引（可选，需要 embedding 模型）
│       ├── build_index.py     ← 构建向量索引
│       └── embeddings/        ← 预计算的向量
│
├── share/                     ← Git 同步共享区
│   ├── public/                ← 开源共享内容
│   └── .gitignore             ← private/ 在此排除
│
└── references/                ← 参考仓库（git clone 下来的）
    ├── ctf-skills/            ← ljagiello/ctf-skills
    ├── solve-it/              ← SOLVE-IT-DF/solve-it
    └── hack-skills/           ← yaklang/hack-skills
```

---

## 四、核心机制详解

### 4.1 多 Agent 协调 — 基于文件系统的去中心化协作

**为什么不用框架（LangGraph / CrewAI / AutoGen）？**
- 这些框架都绑定 Python + 特定 LLM SDK，违反"Agent 无关"原则
- 在离线环境安装这些框架本身就是问题
- 文件系统是唯一保证跨平台、跨 Agent、零依赖的通信方式

**协调协议（File-based Coordination Protocol, FCP）**：

```
coordination/shared/
├── status.yaml         ← 全局状态（谁在线、当前阶段）
├── tasks/
│   ├── pending/
│   │   └── TASK-003.yaml   ← { assigned_to: network, priority: high,
│   │                           description: "分析 pcap 中的异常流量",
│   │                           context: "发现可疑 IP 192.168.1.100",
│   │                           depends_on: [] }
│   ├── active/
│   │   └── TASK-001.yaml   ← { status: active, agent: computer, progress: 70%,
│   │                           last_update: "2024-01-01T12:00:00" }
│   └── done/
│       └── TASK-002.yaml   ← { result: "发现注册表残留键值...",
│                               artifacts: ["evidence/reg_export.txt"] }
├── findings/
│   └── FIND-001.yaml       ← { type: evidence, source: computer,
│                               summary: "发现用户删除了 Chrome 历史记录",
│                               details: "...", confidence: high,
│                               tags: [browser-forensics, anti-forensics] }
└── messages/
    └── MSG-001.yaml         ← { from: main, to: all, type: broadcast,
                                 content: "更新：嫌疑人使用了 VPN" }
```

**工作流**：
1. **Main（总指挥）** 启动 → 分析案件 → 创建初始任务分配到 `tasks/pending/`
2. **各角色 Agent** 轮询 `tasks/pending/`，认领属于自己的任务 → 移到 `active/`
3. 完成后 → 移到 `done/` + 写入 `findings/`
4. **Main** 监控 `done/` 和 `findings/`，根据新线索创建后续任务
5. 任何 Agent 发现需要其他 Agent 协助 → 写 `messages/`

**优势**：
- 任何 Agent 工具（Windsurf/Cursor/Claude Code/终端脚本）都可以读写文件
- 离线友好，零网络依赖
- 人工也可以直接编辑这些 YAML 文件参与协作
- 多机协作：把 `shared/` 放到网络共享目录或 Git 同步即可

### 4.2 启动流程 — Main 的案件分析与分工

当用户启动时，Main Agent 的职责：

```
[用户启动]
    ↓
[1. 环境检测]
    - 当前模式？（训练/比赛/测试）
    - 网络状态？（在线/离线/局域网）
    - 可用模型？（本地/远程/人工）
    - 可用工具？（检查 toolchain/registry.yaml）
    ↓
[2. 案件/题目分析]
    - 读取题目/案件描述
    - 识别涉及的设备类型（手机/电脑/服务器/网络）
    - 识别涉及的取证领域（内存/磁盘/网络/密码...）
    - 查询知识库：是否有类似题型的经验？
    ↓
[3. 生成分工方案]
    - 需要哪些角色？
    - 每个角色的优先任务？
    - 角色间的依赖关系？
    ↓
[4. 输出启动指令]
    - 为每个角色生成完整的启动提示词
    - 包含：角色定义 + 当前任务 + 上下文 + 策略
    - 用户在相应窗口/Agent 中加载即可
```

### 4.3 WriteUp 数据格式

```yaml
# knowledge/writeups/2024-FIC/q15.yaml
id: "2024-FIC-Q15"
competition: "2024 FIC 决赛"
question_number: 15
content: |
  分析给定的内存镜像，找出攻击者使用的恶意程序名称。
answer: "mimikatz.exe"
verification:
  status: "verified_correct"   # unverified | verified_correct | verified_wrong | partial
  verified_by: "human"         # human | ai_cross_check | competition_official
  verified_date: "2024-05-01"

walkthrough: |
  ## 步骤（人工/弱模型可复现）
  1. 使用 Volatility 3 加载内存镜像
     ```
     vol3 -f memory.dmp windows.pslist
     ```
  2. 在进程列表中查找异常进程...
  3. ...

tools_used:
  - name: "volatility3"
    config_path: "toolchain/configs/volatility3.yaml"
    platform: [windows, linux]
  - name: "strings"
    config_path: null
    platform: [linux]

tags:
  technique: ["T0023-memory-process-analysis", "T0045-credential-extraction"]
  category: ["memory-forensics", "malware-analysis"]
  difficulty: "medium"
  os: "windows"

progress:
  status: "completed"        # not_started | in_progress | completed
  started_date: "2024-04-28"
  completed_date: "2024-05-01"
  notes: "第一次用 vol2 失败，vol3 成功"

contributor: "anonymous"
created: "2024-05-01"
updated: "2024-05-01"
```

### 4.4 知识索引 — 混合方案

```
[查询] "如何从内存镜像中提取恶意进程？"
    ↓
[第一层：标签过滤（零算力）]
    → tags 匹配: memory-forensics, malware-analysis, process-analysis
    → 命中 23 篇文档
    ↓
[第二层：关键词评分（零算力）]
    → TF-IDF / BM25 排序
    → Top 10
    ↓
[第三层（可选）：语义精排（需 embedding 模型）]
    → 向量相似度重排序
    → Top 5
    ↓
[返回结果]
```

离线/低算力环境：只走前两层，已经足够用。
有算力时：三层全开，精度更高。

### 4.5 外部知识采集管道

```
[输入源]
    - URL（博客/论坛/公众号文章）
    - PDF 文档
    - Git 仓库
    - 手动输入
    ↓
[提取器]
    - HTML → Markdown（readability 算法）
    - PDF → 文本
    - Git → 遍历 .md 文件
    ↓
[标准化]
    - 打标签（自动 + 人工校正）
    - 生成摘要
    - 分配 SOLVE-IT 分类编号
    ↓
[入库]
    → knowledge/reference/articles/
    → 更新索引
```

---

## 五、你的多 Agent 思路评价

### 你想的哪些是对的

1. **Main 先分析再分工** — 这正是 D-CIPHER 的 Auto-prompter + Planner 模式，已被学术证明有效
2. **角色预设知识库** — ctf-skills 和 pentest-ai-agents 都是这么做的，每个角色带专属 skill 文件
3. **文件系统交换** — 在离线/跨 Agent 场景下，这是最务实的方案。CrewAI 等框架也支持 file-based memory，但它们是锦上添花，文件系统是底线
4. **skill 可手动编辑** — 纯 Markdown 格式保证了这一点，不需要编程能力就能修改
5. **多机协作** — 共享目录是成熟方案，局域网 SMB 共享即可

### 需要补充/修正的地方

1. **Agent 间不应该"聊天"，而应该"交换结构化数据"**
   - 自由文本消息在弱模型上会产生大量噪音
   - 应该用结构化的 YAML（发现、任务、状态），而不是自由对话
   - 只有 Main 汇总时才需要理解自然语言

2. **不要期望弱模型能自主轮询和协调**
   - 弱模型（如本地 7B/14B）很难可靠地执行"检查 pending 目录 → 认领任务 → 执行 → 回写"这种自主循环
   - 现实方案：**用一个轻量脚本做调度**，模型只负责"给我一个任务描述，我返回结果"
   - 即：调度逻辑用代码，推理逻辑用模型

3. **并行策略要分层**
   - 同一题多模型竞速（verialabs 方案）：适合有算力时
   - 不同题分配不同 Agent：适合比赛场景
   - 同一题同一模型多次采样投票（self-consistency）：适合弱模型

4. **关于"AI 做过的题 = 预训练见过"的担忧**
   - 现有研究表明：模型在 CTF 上的表现和是否"见过"关系不大，关键是**推理能力和工具使用能力**
   - D-CIPHER 论文中，同一框架用不同模型效果差异显著，证明框架设计比预训练数据更重要
   - **你的知识库沉淀的是"方法论"而非"答案"，这始终有价值**

5. **安全考虑**
   - 知识库投毒：对 public 共享内容需要签名/校验机制
   - 反作弊：测试模式下的网络隔离不能靠 prompt 约束，应该用系统级网络策略
   - 敏感数据：private 目录永不同步，用 .gitignore 硬隔离

---

## 六、与现有方案的关键差异（我们的创新点）

| 维度 | 现有方案 | AutoForensicAI v2 |
|---|---|---|
| 离线支持 | 无 | **核心设计原则** |
| Agent 兼容 | 绑定特定框架 | **纯文件协议，任何 Agent 可用** |
| 人机协同 | AI 独立解题 | **AI 输出可复现步骤，人工可介入** |
| 知识持续进化 | 静态技能文件 | **WriteUp + 外部学习 + 协作共享** |
| 实战导向 | CTF 竞赛 | **兼顾 CTF 和真实案件取证** |
| 弱模型支持 | 依赖强模型 | **索引 + 并行 + 结构化协议** |

---

## 七、待决策事项

以下是需要你确认的设计选择：

1. **调度器实现**：用 Python 脚本还是 PowerShell 脚本做 Agent 调度？
   - Python 跨平台更好，但离线环境需要预装
   - PowerShell Windows 原生，但 Linux 上不方便

2. **向量索引的 embedding 模型**：
   - 离线场景推荐 `bge-small-zh-v1.5`（中文优化，模型仅 90MB）
   - 也可以用 `all-MiniLM-L6-v2`（英文优化，更小）

3. **知识库的中英文策略**：
   - 国内电子取证比赛以中文为主
   - 但 ctf-skills 等参考资料全是英文
   - 建议：知识库双语并存，标签用英文，正文按来源语言

4. **优先实现顺序**：
   - A. 先搭知识库结构 + WriteUp schema
   - B. 先搭 Agent 角色 + 协调协议
   - C. 先做工具链安装脚本

---

## 八、待下载的参考仓库（网络恢复后）

| 仓库 | 用途 | 命令 |
|---|---|---|
| ljagiello/ctf-skills | 技能库参考 | `git clone --depth 1 https://github.com/ljagiello/ctf-skills.git references/ctf-skills` |
| SOLVE-IT-DF/solve-it | 取证分类体系 | `git clone --depth 1 https://github.com/SOLVE-IT-DF/solve-it.git references/solve-it` |
| yaklang/hack-skills | 安全技能参考 | `git clone --depth 1 https://github.com/yaklang/hack-skills.git references/hack-skills` |
| NYU-LLM-CTF/nyuctf_agents | D-CIPHER 实现参考 | `git clone --depth 1 https://github.com/NYU-LLM-CTF/nyuctf_agents.git references/nyuctf_agents` |
| CKE-Proto/solve_it_mcp | SOLVE-IT MCP 服务 | `git clone --depth 1 https://github.com/CKE-Proto/solve_it_mcp.git references/solve_it_mcp` |
| mukul975/Anthropic-Cybersecurity-Skills | 754 条安全技能 | `git clone --depth 1 https://github.com/mukul975/Anthropic-Cybersecurity-Skills.git references/cybersec-skills` |
