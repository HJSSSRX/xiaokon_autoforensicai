# ForHacker — AI-Driven Digital Forensics & Security Automation

> 让 AI 成为你的取证搭档，而不只是一个聊天框。

ForHacker 是一套基于提示词工程的多 Agent 协作系统，专为电子取证、CTF 竞赛和安全分析设计。它不是一个需要安装的软件——它是一组精心设计的提示词、知识库和 CLI 工具，运行在你已有的 AI 编程助手上。

---

## 核心理念

```
用户说 "小空自己动"
  → AI 读取核心 prompt，变身为取证主设计者 "小空"
  → 小空分析证据、分配角色、生成专家 prompt
  → 用户开多窗口，每个窗口一个专家角色
  → 角色之间通过文件系统协作
  → 每次做题都往知识库写入可复用的方案
  → 下次遇到同类题，搜到方案直接用
```

**三个设计决策让 ForHacker 与众不同：**

1. **CLI 优先** — 工具通过命令行调用（vol3、tshark、sqlmap...），不依赖 MCP，token 消耗降低 35 倍
2. **平台无关** — 同一套 prompt 支持 Windsurf、Cursor、Claude Code、甚至纯终端 AI
3. **知识复利** — 每次工作都产生结构化方案，知识库越用越强

---

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/HJSSSRX/xiaokon_autoforensicai.git forhacker
cd forhacker
```

### 2. 一键部署工具

```powershell
.\install.ps1              # 安装所有工具（scoop + pip + winget）
.\install.ps1 -Check       # 只检查，不安装
.\install.ps1 -Docker      # 额外拉取 Docker 镜像（Kali, REMnux, SIFT）
.\install.ps1 -WSL         # 额外安装 WSL 工具（steghide, foremost...）
.\install.ps1 -Role pentest # 只安装渗透测试工具
```

查看工具状态：
```powershell
python tools\tool_status.py            # 查看全部
python tools\tool_status.py --missing  # 只看缺少的
python tools\tool_status.py --find tshark  # 找具体工具路径
```

工具清单统一维护在 `tools/manifest.yaml`，新增工具只需加一条记录。

### 3. 用你的 AI 打开项目目录

在 Windsurf / Cursor / Claude Code 中打开项目文件夹，然后说：

```
小空自己动
```

AI 会读取核心 prompt 并进入 Main Designer 模式，引导你选择工作模式。

---

## 六种工作模式

| 模式 | 说明 | 适用场景 |
|---|---|---|
| **比赛模式** | 多角色并行分析，时间优先 | CTF 竞赛、取证比赛 |
| **全自动训练** | 已知答案，自动解题 + 验证 + 写入知识库 | 批量刷题、建设知识库 |
| **半自动训练** | AI 解题，用户审核 WriteUp | 学习新领域、审查 AI 方案 |
| **灌知识** | 从 URL/文档/WriteUp 提取结构化知识 | 快速吸收外部资源 |
| **教育模式** | AI 出题 + 讲解 + 验证 | 新手学习 |
| **顾问模式** | 问问题，AI 结合知识库回答 | 随时查阅、快速咨询 |

---

## 项目结构

```
forhacker/
├── prompts/
│   ├── main.md                  # 核心 — Main Designer (小空) 的完整 prompt
│   ├── roles/                   # 5 个专家角色 prompt 模板
│   │   ├── computer_analyst.md  #   磁盘/内存/注册表/事件日志
│   │   ├── mobile_analyst.md    #   Android/iOS/微信/通话记录
│   │   ├── network_analyst.md   #   流量分析/协议取证
│   │   ├── web_pentester.md     #   Web 渗透/注入/XSS/SSRF
│   │   └── stego_crypto_analyst.md  # 隐写/编码/密码学
│   └── protocols/               # 工作流程定义
│       ├── collaboration.md     #   多角色协作规范
│       ├── training_auto.md     #   全自动训练流程
│       └── knowledge_ingest.md  #   知识灌入流程
│
├── knowledge/                   # 知识库 — 系统的核心资产
│   ├── solved/                  #   已验证的解题方案 (Markdown + YAML 标签)
│   ├── skills/                  #   各角色 CLI 命令速查表
│   │   ├── computer/
│   │   ├── mobile/
│   │   ├── network/
│   │   ├── web/
│   │   └── stego_crypto/
│   └── cards/                   #   从外部资源提取的知识卡
│
├── tools/
│   ├── manifest.yaml           # 工具清单（唯一真相源）
│   ├── tool_status.py          # 查询工具安装状态 + 路径
│   ├── kb_search.py            # 知识库搜索 (支持中英文自然语言查询)
│   ├── collab_sync.py          # 协作同步 (Git + LAN)
│   └── e01_reader.py           # E01/VMDK 镜像读取器
│
├── shared/                      # 运行时多角色协作目录 (YAML 文件)
├── install.ps1                  # 一键部署脚本（读 manifest 自动安装）
├── bootstrap.ps1                # (旧版) 工具环境检查脚本
├── tests/                       # 端到端测试
│
├── CLAUDE.md                    # Claude Code 触发入口
├── .cursorrules                 # Cursor 触发入口
└── .windsurf/                   # Windsurf 触发入口
    ├── rules/autoforensicai.md
    └── workflows/xiaokong.md
```

---

## 知识库

ForHacker 的知识库是纯 Markdown 文件，每个文件有 YAML frontmatter 标签，支持多维度搜索。

> **📦 知识库可独立使用**：不需要本框架，直接 `git clone https://github.com/HJSSSRX/autoforensicai_data.git` 即可搜索和使用所有题解。
> 详见 [autoforensicai_data](https://github.com/HJSSSRX/autoforensicai_data)

### 解题方案格式 (`knowledge/solved/*.md`)

```markdown
---
tags: [memory_forensics, volatility, windows, process_analysis]
tools: [vol3, strings]
category: memory_forensics
difficulty: medium
source: ctfshow_forensics_03
date: 2026-05-05
verified: true
---
# Windows Memory Analysis — Suspicious Process

## Problem
Given a Windows memory dump, identify a suspicious process.

## Solution Steps
1. `vol3 -f memory.dmp windows.pslist` → 找异常 PPID
2. `vol3 -f memory.dmp windows.pstree` → 检查父子关系
3. `vol3 -f memory.dmp windows.netscan` → 检查网络连接
...

## Key Takeaways
- svchost.exe 的父进程必须是 services.exe
- 多个 lsass.exe 实例 = 几乎确认恶意

## Answer
flag{...}
```

### 搜索知识库

```bash
# 按标签
python tools/kb_search.py --tags memory_forensics volatility

# 按工具
python tools/kb_search.py --tools vol3 strings

# 全文搜索
python tools/kb_search.py --text "process injection"

# 自然语言查询 (中英文均可)
python tools/kb_search.py --ask "内存取证怎么查可疑进程"
python tools/kb_search.py --ask "PNG图片隐写怎么提取"
python tools/kb_search.py --ask "how to find SQL injection"
```

`--ask` 模式自动完成：中文分词 → 中英文别名扩展 → 标签/工具/全文三维度搜索 → 相关度排序。

---

## 多 Agent 协作

在比赛模式下，多个 AI 通过 `shared/` 目录的 YAML 文件交换信息，支持三种模式：

| 模式 | 场景 | 命令 |
|---|---|---|
| **单机多窗口** | 同一台电脑多个 AI 窗口 | 直接读写 shared/ |
| **Git 同步** | 有互联网，多台电脑 | `python tools/collab_sync.py git-push/pull` |
| **LAN 同步** | 断网/局域网 | `python tools/collab_sync.py lan-serve/pull/push` |

| 文件 | 用途 | 写入方 |
|---|---|---|
| `findings.yaml` | 证据发现（追加写入） | 所有角色 |
| `answers.yaml` | 答案汇总表 | 主设计师 |
| `questions.yaml` | 跨角色提问与回答 | 所有角色 |
| `timeline.yaml` | 统一事件时间线 | 所有角色 |
| `progress.yaml` | 各角色工作进度 | 各角色更新自己 |

小空（Main Designer）主动监控进度、维护答案表、路由跨角色线索、调整策略。

---

## 支持的工具链

| 领域 | 主要工具 |
|---|---|
| 内存取证 | Volatility 3, strings |
| 磁盘取证 | Sleuth Kit (mmls/fls/icat), foremost, binwalk |
| Windows 日志 | Chainsaw, Hayabusa |
| 注册表 | RegRipper |
| 网络分析 | tshark, nmap, tcpdump |
| 手机取证 | ALEAPP, iLEAPP, ADB, MVT |
| Web 渗透 | sqlmap, ffuf, gobuster, nuclei, nikto, hydra |
| 隐写/密码 | steghide, zsteg, john, hashcat, openssl |
| 逆向工程 | Ghidra, Radare2 |

用 `install.ps1` 一键部署，用 `python tools/tool_status.py` 查看状态和路径。
工具清单维护在 `tools/manifest.yaml`。

---

## 设计哲学

### 为什么不写代码编排？

业界常见方案（NYU CTF Agents、ctf-agent 等）用 Python 代码创建 Agent 实例、管理消息队列。ForHacker 不走这条路——我们用 **提示词驱动 AI 行为，用文件系统做状态同步**。

好处：
- 零依赖安装
- 任何 AI 平台都能用
- 弱模型也能按 solved 文件的命令逐步执行
- 人可以直接阅读和编辑所有文件

### 为什么 CLI 优先？

通过 MCP 调用工具：约 7000 token/次（工具描述 + JSON schema + 响应解析）。
通过 CLI 调用工具：约 200 token/次（一行命令 + 输出文本）。

对于取证分析这种需要大量工具调用的场景，35 倍的 token 差距意味着同样的预算能做多得多的工作。

### 知识库为什么是 Markdown？

- 人可读、可编辑
- Git 友好（diff 清晰）
- grep 可搜索
- 零依赖（不需要数据库）
- 每个文件独立，不会整库损坏

---

## 许可证

MIT

---

## 致谢

参考和借鉴了以下开源项目的设计思路：
- [NYU CTF Agents](https://github.com/NYU-LLM-CTF) — 多 Agent 架构
- [ctf-agent](https://github.com/ctf-agent) — Swarm 竞速与消息总线
- [pentest-ai-agents](https://github.com/anthropics/pentest-ai-agents) — 角色定义与 Token 优化
- [ctf-skills](https://github.com/anthropics/ctf-skills) — 结构化安全技能库
- [SOLVE-IT](https://github.com/nicholasmckinney/solve-it) — 取证知识框架
