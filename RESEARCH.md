# AutoForensicAI v2 — 深度调研报告

> 基于对 8 个 GitHub 参考仓库的源码级分析，提炼可直接复用的架构模式和技术方案。

---

## 一、参考仓库总览

| 仓库 | 规模 | 核心价值 | 路径 |
|---|---|---|---|
| **ctf-skills** | 15 个 skill 文件, ~400KB 知识 | 取证技能的最佳格式范例 | `references/ctf-skills/` |
| **ctf-agent (verialabs)** | Coordinator + Swarm 架构 | 多模型并行竞速的工业级实现 | `references/ctf-agent/` |
| **nyuctf_agents (D-CIPHER)** | Planner + Executor + Auto-prompter | 学术验证的多 Agent 分工架构 | `references/nyuctf_agents/` |
| **solve-it** | 54 techniques + 300 weaknesses + 252 mitigations | 电子取证分类体系（MITRE ATT&CK 式） | `references/solve-it/` |
| **solve_it_mcp** | MCP server for SOLVE-IT | 让 LLM 直接查询取证知识库 | `references/solve_it_mcp/` |
| **pentest-ai-agents** | 35 个子 Agent + SQLite 持久化 | 角色化 Agent 设计 + 跨会话状态 | `references/pentest-ai-agents/` |
| **hack-skills** | 158 个安全技能目录 | 全栈安全知识参考 | `references/hack-skills/` |
| **cybersec-skills** | 754 skills, 5 框架映射 | 最大规模 Agent 安全技能库 | `references/cybersec-skills/` |

---

## 二、关键架构模式深度分析

### 2.1 verialabs/ctf-agent — Coordinator + Swarm 并行竞速

这是目前最先进的 CTF 自动化实战方案（BSidesSF 2026 满分）。

**核心架构**：
```
Coordinator (LLM)
  ├── fetch_challenges    → 获取题目列表
  ├── spawn_swarm(题目)   → 为每道题创建 Swarm
  ├── check_swarm_status  → 检查各 Swarm 进度
  ├── bump_agent          → 向 Solver 注入提示
  ├── read_solver_trace   → 读取 Solver 日志
  ├── broadcast           → 向所有 Solver 广播消息
  └── kill_swarm          → 停止 Swarm

ChallengeSwarm (per challenge)
  ├── Solver[claude-sdk/claude-opus]
  ├── Solver[codex/gpt-5.4]
  ├── Solver[codex/gpt-5.4-mini]
  └── Solver[codex/gpt-5.3-codex]
      ↓ 共享
  ChallengeMessageBus (发现共享)
      - post(model, content)        → 发布发现
      - check(model) → [Finding]    → 获取其他模型的未读发现
      - broadcast(content)          → 广播消息
```

**关键设计决策（可直接复用）**：

1. **MessageBus**: Append-only 的发现列表 + 每个模型维护自己的游标(cursor)
   - 零依赖，纯内存结构
   - 互不阻塞，各自按需读取
   - **我们的适配**：改为文件系统版本（JSON 文件 + 游标文件）即可离线使用

2. **Swarm 竞速 + 失败重试 (bump)**:
   - Solver 失败后不立即放弃，等冷却期后注入其他 Solver 的发现再重试
   - 冷却时间递增：30s → 60s → 90s → ... → 300s
   - 连续 3 次错误才真正放弃
   - **我们的适配**：弱模型场景下这个策略更重要，多次重试 + 交叉注入

3. **Flag 提交去重 + 冷却**:
   - 全局去重：已提交过的 flag 不再重复提交
   - 每个模型独立计数错误次数
   - 冷却递增：0s → 30s → 120s → 300s → 600s
   - **我们的适配**：防止弱模型反复提交错误答案

4. **Quota Fallback**: claude-sdk 配额用尽 → 自动降级到 bedrock API
   - **我们的适配**：在线模型不可用 → 自动降级到本地模型

5. **模型规格格式**: `provider/model_id/effort_level` (如 `claude-sdk/claude-opus-4-6/max`)
   - **我们的适配**：`local/deepseek-r1/high`, `api/deepseek-v3/medium`, `human/manual/na`

### 2.2 D-CIPHER (NYU) — Planner-Executor 分工

**核心代码结构（agent.py, 564 行）**：

```python
PlannerExecutorSystem
  ├── AutoPromptAgent     # 探索环境 → 生成动态 prompt
  │     ├── run_one_round()         # 跑命令探索
  │     └── GenAutoPromptTool       # 生成 prompt 给 Planner
  │
  ├── PlannerAgent        # 制定计划 → 委派任务
  │     ├── run_one_round()         # 思考 + 委派
  │     └── DelegateTool            # 创建 Executor 任务
  │
  └── ExecutorAgent[]     # 执行具体任务 → 返回摘要
        ├── run_one_round()         # 执行命令
        └── FinishTaskTool          # 返回任务摘要
```

**关键机制**：

1. **Executor 创建全新对话**: `executor.new()` → 每个任务一个全新 Executor，独立对话历史
   - Planner 只看 Executor 返回的摘要，不看全部对话
   - **巨大优势**：Context 不膨胀，弱模型也能 focus

2. **超时兜底**: Executor 超时没调用 FinishTask → 系统强制再问一次要求总结
   - 如果还是失败 → 返回 "finish_empty" 或 "finish_error" 给 Planner

3. **成本控制**: `max_cost` 全局限制，所有 Agent 共享成本池

4. **退出原因追踪**: solved / giveup / cost / max_rounds / error → 完整日志

**对我们的核心启示**：
- Planner 不应该自己动手执行，只委派和看摘要
- 每个 Executor 是一次性的，用完即丢
- 这个模式天然适合弱模型：每个 Executor 任务足够小

### 2.3 ctf-skills — 知识文件格式标准

**SKILL.md 格式 (frontmatter + 内容)**：
```yaml
---
name: ctf-forensics
description: Provides digital forensics and signal analysis techniques for CTF challenges...
license: MIT
compatibility: Requires filesystem-based agent...
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch WebSearch
metadata:
  user-invocable: "false"
---

# 正文：分层结构
## Quick Start Commands        ← 快速参考
## Windows Event Logs          ← 按子领域分节
## Steganography               ← 每节有一句话摘要 + 详见 xx.md
## When to Pivot               ← 什么时候该切换到其他 skill
```

**子文件分层（ctf-forensics/ 目录）**：
```
SKILL.md              ← 入口索引（37KB，最全面的速查表）
windows.md            ← 23KB Windows 取证详细技术
linux-forensics.md    ← 19KB Linux 取证
network.md            ← 23KB 基础网络取证
network-advanced.md   ← 27KB 高级网络取证
disk-and-memory.md    ← 21KB 磁盘/内存取证基础
disk-advanced.md      ← 22KB 高级磁盘取证
disk-recovery.md      ← 32KB 数据恢复
steganography.md      ← 31KB 隐写术基础
stego-image.md        ← 31KB 图像隐写
stego-advanced.md     ← 20KB 高级隐写1（音频/信号）
stego-advanced-2.md   ← 21KB 高级隐写2（视频/图像变换）
signals-and-hardware.md ← 30KB 硬件信号解码
peripheral-capture.md ← 13KB USB/HID/蓝牙
3d-printing.md        ← 4KB 3D打印取证
```

**关键特征**：
- **双层结构**：SKILL.md 是入口（一句话摘要），详细内容在子文件
- **每个技术都有可执行命令**：不是纯理论，而是 `vol3 -f memory.dmp windows.pslist` 这样的命令
- **When to Pivot**：告诉 AI 什么时候该切换到其他技能，避免在错误方向浪费时间
- **平台安装命令**：apt / brew / pip / gem 全覆盖

### 2.4 SOLVE-IT — 取证分类体系

**数据结构**：
```json
// DFT-1001.json (Technique)
{
  "id": "DFT-1001",
  "name": "Triage",
  "description": "Digital forensic triage...",
  "weaknesses": ["DFW-1001", "DFW-1002", "DFW-1003"],
  "CASE_input_classes": ["...DeviceSet"],
  "CASE_output_classes": ["...PrioritizedDeviceSet"],
  "references": [{"DFCite_id": "DFCite-1115"}]
}

// DFW-1001.json (Weakness)
{
  "id": "DFW-1001",
  "name": "Excluding a device that contains relevant information",
  "categories": ["ASTM_INCOMP"],
  "mitigations": []
}
```

**分类编号体系**：
- **DFO-xxxx**: Objective（调查目标）— 15 个目标
- **DFT-xxxx**: Technique（调查技术）— 54 个技术
- **DFW-xxxx**: Weakness（弱点/陷阱）— 300 个弱点
- **DFM-xxxx**: Mitigation（缓解措施）— 252 个缓解

**调查流程（solve-it.json 定义的目标序列）**：
1. DFO-1015: Prepare for investigation（准备）
2. DFO-1014: Find potential evidence sources（寻找证据源）
3. DFO-1005: Prioritize evidence sources（优先级排序）
4. DFO-1010: Preserve digital evidence（保全证据）
5. DFO-1021: Access device data（访问设备数据）
6. DFO-1016: Overcome protection mechanisms（突破保护）
7. DFO-1006: Acquire data（采集数据）
8. ... → Analyze → Report

**MCP Server 提供 20 个工具**：
- `search` - 跨类型关键词搜索
- `get_technique_details` - 获取技术详情
- `get_weaknesses_for_technique` - 获取技术的弱点
- `get_mitigations_for_weakness` - 获取弱点的缓解措施

### 2.5 pentest-ai-agents — Findings DB 持久化

**最关键的发现**：他们用 **SQLite** 做跨会话状态持久化，而不是 RAG 或向量库。

**schema.sql 定义 7 个表**：
```sql
engagements     -- 项目/案件
hosts           -- 发现的主机
services        -- 发现的服务
vulns           -- 漏洞（含 MITRE ID, 严重级别, 状态, PoC 输出）
credentials     -- 凭据
chains          -- 攻击链
session_log     -- 每个 Agent 的操作日志
```

**为什么不用 RAG**：
> "Compared to vector-based approaches, this uses zero LLM tokens for storage and retrieval.
> Data goes in and out as structured queries, not embeddings."

**Agent 集成方式**：
- 每个 Agent 检查 `findings.sh` 是否可用
- 可用则写入发现；不可用则正常工作，不依赖
- 不同 Agent 写不同类型数据（recon → hosts, vuln-scanner → vulns）

**跨会话工作流**：
```
Session 1: Recon → 写入 hosts, services
Session 2: 漏洞评估 → 读取 hosts, 写入 vulns
Session 3: 利用 → 读取 vulns, 写入 chains, creds
Session 4: 报告 → 读取全部数据
```

**Token 优化策略**（TOKEN-OPTIMIZATION.md）：
- Lite 模式：咨询类 Agent 用 Haiku（降 90% 成本），执行类 Agent 保持 Sonnet
- 每个 Agent 系统提示从 ~900 到 ~7600 tokens 不等
- 建议短对话、精确提示、避免不必要的 swarm

### 2.6 cybersec-skills — 大规模技能映射

**754 个技能, 5 重框架映射**：
- MITRE ATT&CK v18
- NIST CSF 2.0
- MITRE ATLAS (AI/ML 威胁)
- MITRE D3FEND (防御)
- NIST AI RMF (AI 风险管理)

**index.json 提供全局检索**：200KB 的索引文件，包含所有技能的 ID、名称、映射关系。

---

## 三、可直接复用的组件

### 3.1 知识库内容（可直接整合）

| 来源 | 可复用内容 | 规模 |
|---|---|---|
| ctf-skills/ctf-forensics/ | Windows/Linux/网络/磁盘/内存/隐写术取证技能 | 15 文件, ~350KB |
| solve-it/data/ | 电子取证分类体系 (DFT/DFW/DFM) | 54 技术 + 300 弱点 + 252 缓解 |
| hack-skills/skills/ | 内存取证 Volatility, 流量分析, 隐写术等 | 158 目录 |
| cybersec-skills/skills/ | 通用安全技能（可按需选取取证相关） | 754 技能 |

### 3.2 架构模式（应采用）

| 模式 | 来源 | 为什么 |
|---|---|---|
| Planner-Executor 分工 | D-CIPHER | 学术验证，降低对单模型能力的要求 |
| MessageBus 发现共享 | ctf-agent | 零依赖的跨 Agent 信息共享 |
| Swarm 并行 + Bump 重试 | ctf-agent | 弱模型以量制胜的核心策略 |
| SQLite 持久化 | pentest-ai-agents | 零 token 成本的跨会话状态 |
| SKILL.md frontmatter | ctf-skills | Agent 无关的技能格式标准 |
| DFT/DFW/DFM 分类 | SOLVE-IT | 电子取证领域已有学术分类体系 |

### 3.3 工具（可集成）

| 工具 | 用途 | 来源 |
|---|---|---|
| solve_it_mcp | MCP server 查询取证知识 | solve_it_mcp |
| findings.sh | Shell 脚本操作 SQLite 证据库 | pentest-ai-agents |

---

## 四、与上一版 DESIGN.md 的对比和修正

### 需要修改的设计决策

1. **协调机制**：之前设计的纯 YAML 文件交换过于简单
   - **修正**：采用 ctf-agent 的 MessageBus 模式（文件系统版），支持游标、去重、广播
   - 同时保留 YAML 任务文件做 Planner-Executor 级别的任务委派

2. **持久化方案**：之前只考虑了文件
   - **修正**：核心状态用 SQLite（零 token 成本），知识库用 Markdown 文件（人可读）

3. **知识库格式**：之前的 WriteUp schema 太复杂
   - **修正**：采用 SKILL.md frontmatter + 正文的双层结构，更符合 Agent 通用标准

4. **Agent 角色**：之前只按设备类型分
   - **修正**：增加功能性角色（Auto-prompter / Planner / Executor），和领域角色（mobile/computer/...）正交

### 新增的设计要素

1. **Coordinator → Swarm → Solver 三层架构**（来自 ctf-agent）
2. **Auto-prompter 机制**（来自 D-CIPHER）：先探索再制定计划
3. **Bump 重试 + 交叉注入**（来自 ctf-agent）：失败后注入其他 Agent 的发现
4. **Token 优化分层**（来自 pentest-ai-agents）：咨询型用弱模型，执行型用强模型
5. **模型规格格式标准化**：`provider/model_id/effort_level`

---

## 五、待研究（网络恢复后）

1. 微信公众号文章 https://mp.weixin.qq.com/s/uvsdPsJUuAA3uEBg_bwI6g （需要验证码）
2. DIDCTF 电子数据取证综合平台 (https://forensics.didctf.com/) 的具体功能
3. 更多中文电子取证社区资源
