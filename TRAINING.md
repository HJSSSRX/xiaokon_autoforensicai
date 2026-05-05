# AutoForensicAI v2 — 自动化训练（知识填充）方案

> 系统不只是做题时用，更要在平时**自动积累知识**，使知识库持续进化。

---

## 一、训练的三种模式

```
┌─────────────────────────────────────────────────────┐
│                训练模式总览                            │
├──────────────┬──────────────┬───────────────────────┤
│ 做题训练      │ 外部学习      │ 实战复盘               │
│ (CTF/竞赛)   │ (URL/公众号)  │ (真实案件)             │
├──────────────┼──────────────┼───────────────────────┤
│ 输入: 题目    │ 输入: URL    │ 输入: 案件报告          │
│ 输出: WriteUp │ 输出: 知识卡  │ 输出: 案例记录          │
│ 验证: flag    │ 验证: 人工   │ 验证: 人工              │
└──────────────┴──────────────┴───────────────────────┘
            ↓ 全部写入 ↓
      knowledge/ 知识库
```

---

## 二、做题训练流水线

### 2.1 全自动流程

```
题目输入 → 解析题目元数据 → 分配角色 → Agent 解题
                                         ↓
                              成功?──→ 生成 WriteUp → 写入知识库
                                │
                                └──→ 记录失败 → 标记待人工复盘
```

### 2.2 训练入口命令

```powershell
# 单题训练（手动指定）
python train.py solve --source ctfshow --id "电子取证1" --flag-format "ctfshow{*}"

# 批量训练（从平台拉取）
python train.py batch --source buuoj --category forensics --max 20

# 本地题目训练
python train.py solve --local ./challenges/forensics_01/ --description "内存取证.."

# 从 WriteUp 反向学习（不需要实际做题）
python train.py learn-writeup --file ./writeups/2024_national_forensics.md
```

### 2.3 WriteUp 自动生成格式

解题成功后自动生成标准 WriteUp：

```yaml
# knowledge/writeups/ctfshow_forensics_01.yaml
---
id: ctfshow_forensics_01
competition: CTFShow
category: forensics
subcategory: memory_analysis
title: "Windows 内存分析 - 恶意进程识别"
difficulty: medium
flag: "ctfshow{xxxxxxxx}"
verified: true
created: 2026-05-05
model_used: deepseek-v3
cost_tokens: 45000
solve_time_seconds: 180
---

# 题目描述
...

# 解题过程（可复现）
## Step 1: 识别镜像类型
```
vol3 -f memory.dmp windows.info
```
输出: Windows 10 19041

## Step 2: 查看进程列表
```
vol3 -f memory.dmp windows.pslist
```
发现可疑进程: svchost.exe (PID 4396, PPID 1234 异常)

## Step 3: 提取恶意进程
```
vol3 -f memory.dmp windows.dumpfiles --pid 4396
```
...

# 关键知识点
- DFT-1045: Memory analysis → windows.pslist
- 异常 PPID 是恶意进程的常见特征
- Volatility 3 的 windows.dumpfiles 可直接提取进程内存

# 工具配置
tools:
  - id: volatility3
    command: "vol3 -f {image} {plugin}"
    plugins_used: [windows.info, windows.pslist, windows.dumpfiles]

# 知识标签
tags:
  - memory_forensics
  - volatility
  - windows
  - malware_analysis
  - process_analysis
  
# 关联 SOLVE-IT 技术
solve_it_refs:
  - DFT-1045  # Analyze memory
  - DFT-1046  # Identify running processes
```

### 2.4 WriteUp 质量评估

自动对生成的 WriteUp 做质量评分：

| 维度 | 权重 | 评分标准 |
|---|---|---|
| **可复现性** | 40% | 每步都有具体命令 + 预期输出 |
| **知识提取** | 25% | 标记了知识点、SOLVE-IT 编号、标签 |
| **工具记录** | 15% | 记录了使用的工具和配置 |
| **完整性** | 10% | 题目描述、解题过程、答案都有 |
| **通用性** | 10% | 技巧是否可迁移到其他题目 |

**低质量 WriteUp 自动标记为 `needs_review: true`**。

---

## 三、外部知识学习流水线

### 3.1 支持的输入源

| 来源类型 | 输入方式 | 提取方法 |
|---|---|---|
| **URL（博客/文章）** | `python train.py learn-url --url https://...` | HTML 提取正文 |
| **微信公众号** | 复制粘贴文本 / 转存 HTML | 文本提取 |
| **GitHub 项目** | `python train.py learn-repo --url https://github.com/...` | README + 代码分析 |
| **PDF 文档** | `python train.py learn-pdf --file ./docs/xxx.pdf` | PDF 文本提取 |
| **视频教程** | 字幕文件 / 笔记 | 文本提取 |
| **本地 Markdown** | `python train.py learn-file --file ./notes/*.md` | 直接读取 |

### 3.2 知识提取流程

```
输入源 → 内容提取（去广告/去模板） 
       → AI 结构化（提取关键知识点）
       → 分类标注（领域/技术/工具/SOLVE-IT 编号）
       → 去重检测（与已有知识对比）
       → 写入知识库
       → 更新索引
```

### 3.3 AI 结构化提取 Prompt

```markdown
你是一个电子取证知识提取专家。请从以下内容中提取结构化知识：

## 要求
1. 提取所有涉及的取证/安全技术和工具用法
2. 每个知识点包含：标题、描述、具体命令/步骤、适用场景
3. 标注对应的 SOLVE-IT 技术编号（如果适用）
4. 标注知识领域标签
5. 评估知识的实用程度（1-5 分）

## 输入内容
{content}

## 输出格式 (YAML)
knowledge_cards:
  - title: "..."
    description: "..."
    category: "memory_forensics"
    commands:
      - tool: "volatility3"
        command: "vol3 -f {image} windows.pslist"
        explanation: "列出所有进程..."
    tags: [...]
    solve_it_ref: "DFT-1045"
    quality_score: 4
    source_url: "..."
```

### 3.4 知识卡格式

```yaml
# knowledge/cards/volatility3_pslist_technique.yaml
---
id: K-2026-0523-001
type: technique_card
title: "Volatility 3 进程列表分析"
category: memory_forensics
source:
  type: url
  url: "https://example.com/volatility-tutorial"
  accessed: 2026-05-05
---

# 概述
使用 Volatility 3 的 windows.pslist 插件分析 Windows 内存镜像中的进程。

# 命令
```
vol3 -f <memory_dump> windows.pslist
```

# 关键观察点
- PPID（父进程ID）异常：如 svchost.exe 的 PPID 不是 services.exe
- 进程路径异常：系统进程不在 System32 目录
- 创建时间异常：与系统启动时间差距大

# 适用场景
- 恶意软件分析
- 内存取证
- 事件响应

# 关联
tags: [volatility, windows, process, malware]
solve_it_ref: DFT-1045
related_writeups: [ctfshow_forensics_01, national_2024_mem_03]
```

---

## 四、实战复盘流水线

### 4.1 案件记录格式

```yaml
# knowledge/cases/case_2026_001.yaml
---
id: CASE-2026-001
type: real_case
title: "XX 公司数据泄露事件"
classification: confidential  # public / internal / confidential
date: 2026-05-01
evidence_types: [disk_image, memory_dump, network_capture, mobile_backup]
---

# 案件概述
...

# 分析过程
## 阶段 1: 证据采集
- 使用 FTK Imager 制作硬盘镜像 (SHA256: xxx)
- 使用 WinPmem 采集内存
...

## 阶段 2: 分析
...

# 发现
findings:
  - type: artifact
    description: "发现 PowerShell 远控脚本"
    tool: volatility3
    technique: DFT-1045
...

# 经验教训（写入知识库）
lessons:
  - "Windows Defender MPLog 可能包含被阻止的恶意文件路径"
  - "PowerShell 历史记录默认存储在 ConsoleHost_history.txt"
```

---

## 五、自动化训练调度

### 5.1 训练计划配置

```yaml
# config/training_schedule.yaml
schedule:
  daily:
    - action: learn-url
      sources:
        - "https://forensics.didctf.com/challenges"  # 每日新题
      max_items: 5
      
  weekly:
    - action: batch-solve
      source: ctfshow
      categories: [forensics, misc, crypto]
      max_per_category: 3
      model: deepseek-v3
      
    - action: learn-repo
      urls:
        - "https://github.com/DidierStevens/DidierStevensSuite"
      focus: "new commits this week"
      
  on_demand:
    - action: learn-url     # 手动触发
    - action: learn-writeup # 手动触发
    - action: case-review   # 手动触发

model_selection:
  training:    # 训练时用强模型获取最佳 WriteUp
    primary: "api/deepseek-v3"
    fallback: "local/qwen2.5-32b"
  review:      # 复盘时用弱模型节省成本
    primary: "local/qwen2.5-7b"
  extraction:  # 知识提取用中等模型
    primary: "api/deepseek-v3"
    fallback: "local/qwen2.5-14b"
```

### 5.2 训练仪表盘

```
$ python train.py stats

📊 知识库统计
────────────────────────────────────
WriteUps:       156 (已验证: 142, 待复盘: 14)
知识卡:          283
案例记录:        12

📈 按领域分布
────────────────────────────────────
memory_forensics  ████████████░░░░  42
disk_forensics    ██████████░░░░░░  35
network_forensics █████████░░░░░░░  31
web_security      ████████░░░░░░░░  28
stego             ██████░░░░░░░░░░  20

🔄 最近训练
────────────────────────────────────
2026-05-05  learn-url     3 cards extracted
2026-05-04  batch-solve   5/8 solved, 5 writeups
2026-05-03  learn-repo    12 cards from hack-skills

⚠️  需要关注
────────────────────────────────────
- 14 个 WriteUp 待人工复盘
- crypto 领域知识偏少 (8 cards)
- 上次训练: 2 天前
```

---

## 六、知识索引更新

每次新增知识后自动更新索引：

### 6.1 标签索引 (tags_index.yaml)
```yaml
memory_forensics:
  writeups: [ctfshow_forensics_01, national_2024_mem_03, ...]
  cards: [K-2026-0523-001, ...]
  tools: [volatility3, rekall]
  solve_it: [DFT-1045, DFT-1046]
```

### 6.2 工具索引 (tools_index.yaml)
```yaml
volatility3:
  writeups_using: [ctfshow_forensics_01, ...]
  cards_about: [K-2026-0523-001, ...]
  common_plugins: [windows.pslist, windows.dumpfiles, windows.netscan]
```

### 6.3 全文搜索索引
- 使用 SQLite FTS5 做全文检索（离线可用，零依赖）
- 可选：生成向量嵌入做语义检索（需要模型支持）

---

## 七、训练与做题的闭环

```
                    ┌─────────────┐
                    │  竞赛/实战    │
                    └──────┬──────┘
                           │ 遇到新题
                           ▼
                    ┌─────────────┐
              ┌────>│  知识库检索   │<────┐
              │     └──────┬──────┘     │
              │            │ 找到相关知识  │ 没找到
              │            ▼            │
              │     ┌─────────────┐    │
              │     │ 应用已有知识  │    │
              │     │ 快速解题     │    │
              │     └──────┬──────┘    │
              │            │           │
              │     成功 ←─┤─→ 失败    │
              │            │           │
              │            ▼           ▼
              │     ┌─────────────────────┐
              │     │  Agent 深度分析解题   │
              │     └──────┬──────────────┘
              │            │
              │            ▼
              │     ┌─────────────┐
              └─────│ 生成 WriteUp │
                    │ 更新知识库    │
                    └─────────────┘
```

**核心理念**：每次做题都让知识库变强，下次遇到类似题目时效率更高。
训练时用强模型生成高质量 WriteUp，比赛时弱模型也能通过检索已有知识快速解题。
