# ForensicAI — 小空自己动

> **智能电子数据取证平台**：离线优先 · 模型无关 · Agent 无关 · 教育内嵌

面向国内电子取证比赛（FIC / 平航杯 / 盘古石杯 / 美亚杯）和真实取证场景的智能辅助与教育系统。

---

## 快速入门

### AI Agent 入口

**所有 AI Agent（Windsurf/Cursor/Claude Code/其他）请先读 `AGENTS.md`**

### 人类用户入口

| 你要做什么 | 入口文件 |
|-----------|---------|
| 了解项目全貌 | 本文件 |
| 开始比赛/做题 | `AGENTS.md` → 选策略 → 开始 |
| 部署环境 | `share/QUICKSTART_HUMAN.md` |
| 学习取证 | 教育模式 (`strategies/education_local_solo.yaml`) |
| 了解设计 | `share/SYSTEM_DESIGN.md` |
| 了解项目价值 | `share/PROPOSAL.md` |

### 工作模式

| 模式 | 场景 | 策略文件 |
|------|------|---------|
| **比赛 (云端)** | 线上赛，使用 Claude/GPT 等 | `strategies/competition_cloud_solo.yaml` |
| **比赛 (本地)** | 线下断网赛，本地模型 | `strategies/competition_local_team.yaml` |
| **训练** | 用强模型做历年题，产出知识 | `strategies/training_cloud_solo.yaml` |
| **教育** | 引导新手学习取证 | `strategies/education_local_solo.yaml` |
| **复盘** | 分析比赛表现 | `modes/REVIEW_MODE.md` |

### Windsurf 斜杠命令（`.windsurf/workflows/`）

- `/case-solo` — SOLO 快速模式开局
- `/case-coop` — COOP 协作模式开局
- `/wp-report` — 每 5 题批次报告
- `/team-sync` — TEAM 模式 Git 同步
- `/env-check` — 环境健康检查

---

## 设计原则

| 优先级 | 原则 | 含义 |
|--------|------|------|
| P0 | **离线优先** | 断网/隔离网络下仍能运行 |
| P1 | **模型无关** | Claude/GPT/DeepSeek/Qwen/本地 7B 均可 |
| P2 | **Agent 无关** | Windsurf/Cursor/Claude Code 均可 |
| P3 | **训练产出 > 运行时推理** | 平时用强模型产知识，比赛用弱模型消费 |
| P4 | **人机共生** | AI 辅助人，人校验 AI |
| P5 | **教育内嵌** | 知识库天然可用于教学 |

## 目录结构

```
ForensicAI (小空自己动)/
│
├── AGENTS.md               # AI Agent 通用入口 (所有 agent 必读)
├── CLAUDE.md               # Claude Code 适配器
├── .cursorrules            # Cursor 适配器
├── .windsurf/rules/        # Windsurf 适配器
├── README.md               # 本文件
├── CHANGELOG.md            # 版本变更记录
│
├── AI_BRAIN/               # AI 持久记忆 (核心)
│   ├── persona.md          # AI 行为定义
│   ├── output_contract.md  # 答案输出契约 (5 字段)
│   ├── solved_patterns/    # 已验证解法模式 (8 个)
│   └── tool_inventory.md   # 工具清单
│
├── knowledge/              # 知识内核 (核心)
│   ├── taxonomy.yaml       # 分类标签体系 (7大类 40+子类)
│   ├── solved/             # 结构化题库 (YAML, 按比赛)
│   │   └── 2026fic/        # FIC2026 题解
│   ├── playbook/           # 检材类型方法论 (8 种)
│   ├── sop/                # 确定性 SOP 脚本 (弱模型/人工用)
│   ├── tools/              # 工具注册表 (YAML)
│   ├── wp_index/           # 历年 writeup 索引 (8 场比赛)
│   └── competitions/       # 比赛信息库 (4 大比赛)
│
├── strategies/             # 运行策略配置
│   ├── competition_cloud_solo.yaml
│   ├── competition_local_team.yaml
│   ├── training_cloud_solo.yaml
│   └── education_local_solo.yaml
│
├── modes/                  # 模式定义 (SOLO/COOP/REVIEW)
├── roles/                  # 多机角色 (PC/Phone/Server)
├── cases/                  # 比赛案例 (部分 gitignore)
├── scripts/                # 工具脚本
├── share/                  # 可分发内容
│   ├── SYSTEM_DESIGN.md    # 系统设计文档
│   ├── PROPOSAL.md         # 项目策划书
│   ├── SYSTEM_REVIEW.md    # 方案分析报告
│   └── install/            # 安装脚本
├── worklog/                # 工作日志
│
├── PLAYBOOK.md             # 检材操作检查单
├── KARPATHY_GUIDELINES.md  # AI 编码准则
├── SESSION_START.md        # 会话启动流程
└── WP_FORMAT.md            # 答案格式规范
```

## 知识库

`knowledge/` 是项目核心资产，采用**双模式索引**：

- **模式 A (RAG)**: 向量检索，适用于有推理能力的模型。基于 FAISS + bge-small-zh embedding
- **模式 B (SOP)**: 确定性脚本，适用于弱模型或纯人工。按标签匹配对应 SOP

知识库中每道题包含：元数据、答案、人工可复现步骤、工具配置、教育引导、验证状态。
详细 Schema 见 `share/SYSTEM_DESIGN.md` §3.1。

## 实战数据

| 比赛 | 得分 | AI 耗时 | 成本 |
|------|------|---------|------|
| FIC2026 | 367/600 (61.2%) | 1h | ~$10 |

详细分析见 `share/SYSTEM_REVIEW.md`。

## 开发状态

见 `CHANGELOG.md`。
