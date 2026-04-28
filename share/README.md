# forensics-agent-starter

**电子取证 AI Agent 启动包** — 给 Windsurf + Claude 的一站式取证比赛协作框架。

---

## 这是什么

一个经过 FIC2026 实战检验的 AI 辅助电子取证项目模板。包含：

- **AI 持久化大脑** (`skeleton/AI_BRAIN/`) — 让 AI agent 跨会话保持记忆
- **解题套路库** (`skeleton/AI_BRAIN/solved_patterns/`) — 8 种已验证的取证题型解法
- **工具安装脚本** (`install/`) — 含环境诊断，一键部署 WSL 取证工具链
- **三种协作模式** (`skeleton/modes/`) — SOLO/COOP/TEAM 按需切换
- **FIC2026 完整复盘** (`reference_case/`) — 52 题的解法、踩坑、教训

## 面向谁

- 使用 **Windsurf IDE + Claude** 的取证比赛参赛者
- 想让 AI agent 快速上手电子取证分析的团队
- 电子取证教学/训练场景

## 快速开始

### 人类操作员

```
1. 阅读 QUICKSTART_HUMAN.md
2. 运行 install/00_diagnose.ps1 检查环境
3. 运行 install/01_install_wsl_tools.sh 安装工具
4. 将 skeleton/ 复制为新比赛目录
5. 在 Windsurf 中打开项目，开始协作
```

### AI Agent

```
1. 阅读 QUICKSTART_AGENT.md
2. 读 skeleton/AI_BRAIN/README.md（第一步，强制）
3. 读 skeleton/AI_BRAIN/persona.md
4. 读 skeleton/AI_BRAIN/output_contract.md
5. 按指令开始解题
```

## 目录结构

```
share/
├── README.md                    ← 你正在读的
├── QUICKSTART_AGENT.md          AI agent 启动手册
├── QUICKSTART_HUMAN.md          人类操作手册
├── install/                     安装脚本 + 环境诊断
│   ├── 00_diagnose.ps1          环境诊断（WSL/Python/磁盘/代理）
│   ├── 01_install_wsl_tools.sh  WSL 工具链一键装
│   ├── 02_install_win_tools.ps1 Windows 侧工具
│   └── INSTALL_NOTES.md         装完后的验证清单
├── skeleton/                    项目骨架（复制即用）
│   ├── AI_BRAIN/                AI 持久化大脑
│   ├── knowledge/               知识库
│   ├── modes/                   SOLO/COOP/TEAM/REVIEW
│   ├── roles/                   PC/Phone/Server 角色定义
│   ├── .windsurf/               Windsurf 规则 + 工作流
│   ├── WP_FORMAT.md             答题格式模板
│   └── KARPATHY_GUIDELINES.md   编码准则
└── reference_case/              FIC2026 完整复盘
    ├── RETROSPECTIVE.md         总复盘报告
    ├── LESSONS_LEARNED.md       可迁移教训
    ├── questions.md             题目清单
    └── wp_batches/              7 个 WP 批次文件
```

## 技术栈

- **IDE**: Windsurf（内置 Cascade AI agent）
- **AI 模型**: Claude (Anthropic)
- **OS**: Windows 11 + WSL2 (Ubuntu)
- **核心工具**: sqlite3, sqlcipher, jadx, radare2, python3, pycryptodome, openssl
- **版本控制**: Git（支持多机协作）

## 许可

本项目为个人学习/比赛用途。检材数据不包含在内。
