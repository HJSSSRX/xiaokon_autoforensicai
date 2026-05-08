# 远程协作架构 v3 — 交接文档

> 创建时间: 2026-05-07 14:30
> 上一会话决策者: 用户 + Cascade
> 状态: **设计已确定，待实现**

---

## 0. TL;DR（30秒看懂）

**用户决定彻底放弃 GitHub 协作，全面采用「本机 HTTP Hub + 局域网」方案。**

核心原因：本机 hosts 文件有 27 条 `127.0.0.1 *.github.com` 屏蔽，GitHub 在网络层就走不通。即使绕过 hosts，Git 方案还有"AI 不会主动 push""认证麻烦""非实时"等固有问题。

下一个 AI 接手后要做的 4 件事（按优先级）：
1. **重写 `tools/collab_sync.py`** → 改名 `tools/collab_hub.py`，提供 REST API
2. **更新 `prompts/roles/*.md`** → 把 curl 协作指令嵌入每个角色模板
3. **设计会话恢复机制** → 新增 `session_log.yaml` / `blockers.yaml` / `strategy.yaml`
4. **联调测试** → 本机启动 Hub + 两台远程机做 ping/post/get 测试

---

## 1. 为什么要换方案？历史踩坑记录

### 时间线
1. **第一阶段**：用户要求测试 2026FIC 远程协作，4 个角色（计算机/手机/服务器/二进制）分到 2 远程机 + 2 本机
2. **第二阶段**：选 Git 方案 → 创建 GitHub 仓库失败（gh 没装）→ Python API 创建成功
3. **第三阶段**：`git push` 看似成功，但**远程机一直无法克隆/推送**
4. **第四阶段**：用户检查 hosts 文件，发现 27 条 `127.0.0.1 → github.com` 屏蔽
5. **第五阶段**：调研业界方案（A2A/MCP/CrewAI/AutoGen/LangGraph），确认「HTTP Hub」最匹配我们的场景
6. **第六阶段**：用户拍板「彻底放弃 GitHub」

### 关键发现：我们的场景特殊性
我们的 Agent **不是 Python 进程**，而是 **IDE 里的 AI 编码助手**（Windsurf/Cursor/Claude）。这意味着：
- 不能 `import crewai`/`import autogen`
- Agent 是不透明的，只能给 prompt + 它执行 shell
- 通信能力仅限于：读写文件 + 执行命令行 + HTTP 请求

所以**不能用** CrewAI/LangGraph/AutoGen 这类 Python 框架——它们假设 Agent 是 Python 进程。

### Git 方案的根本缺陷（即使没有 hosts 屏蔽）
1. **AI 不会主动 push** — 拿到 role_prompt 后埋头解题，忘了同步
2. **认证墙** — 每台机器都要配 GitHub 凭据
3. **非实时** — 主设计师只能 fetch 被动检查
4. **指令分离** — 协作指令和任务指令分两份发，AI 只看任务那份

---

## 2. 业界调研结论（详见对话历史）

### 协议层
- **A2A Protocol (Google → Linux Foundation, 2025-04)**：Agent 之间通过 HTTP/JSON-RPC 通信。**最匹配我们的方向**。
- **MCP (Anthropic → Linux Foundation, 2024-11)**：Agent ↔ Tool 标准。我们已用过类似思路。

### 框架层（**对我们都不适用**）
| 框架 | 是否分布式 | 不适用原因 |
|---|---|---|
| CrewAI | ❌ 单进程 | 需要 Python 内运行 Agent |
| LangGraph | ⚠️ 需 Cloud | 同上 |
| AutoGen 0.4 | ✅ gRPC 分布式 | 需要 Python Agent，IDE 内 AI 用不了 |
| MetaGPT | ❌ 单进程 | 同 CrewAI |

### 结论
**自己实现一个 A2A 风格的轻量 HTTP Hub 才是正解。**

---

## 3. v3 架构设计

### 总体拓扑

```
[远程机 1 - 计算机取证]                  [本机 - Main Hub]                  [远程机 2 - 手机取证]
┌──────────────────────┐              ┌────────────────────────┐         ┌──────────────────────┐
│ Windsurf/Cursor AI   │ ──curl POST→ │   collab_hub.py        │ ←POST── │ Windsurf/Cursor AI   │
│  (Computer Analyst)  │ ←─curl GET── │   :8765                │ ─GET──→ │  (Mobile Analyst)    │
└──────────────────────┘              │                        │         └──────────────────────┘
                                       │  ┌──────────────────┐ │
[本机 - Server Analyst]                │  │ shared/          │ │         [本机 - Binary Analyst]
┌──────────────────────┐              │  │  findings.yaml   │ │         ┌──────────────────────┐
│ AI Window 3          │ ──HTTP API──→│  │  progress.yaml   │ │ ←─API── │ AI Window 4          │
│  (Server Analyst)    │              │  │  answers.yaml    │ │         │  (Binary Analyst)    │
└──────────────────────┘              │  │  questions.yaml  │ │         └──────────────────────┘
                                       │  │  timeline.yaml   │ │
                                       │  │  session_log.yaml│ │  ← v3 新增
                                       │  │  blockers.yaml   │ │  ← v3 新增
                                       │  │  strategy.yaml   │ │  ← v3 新增
                                       │  └──────────────────┘ │
                                       │  Main Designer Window │
                                       └────────────────────────┘
```

### REST API 设计

```python
# collab_hub.py — 单文件，stdlib 实现 (http.server)
# 启动: python tools/collab_hub.py serve <case_dir> --port 8765 --bind 0.0.0.0

# 1. 健康检查
GET  /ping                          → {"status": "ok", "version": "v3"}

# 2. 发现（Findings）
POST /findings                      → 追加一条发现（不允许修改别人的）
  body: {from, type, summary, detail, related_to}
GET  /findings                      → 全量
GET  /findings?from=computer        → 按角色过滤
GET  /findings/{id}                 → 单条

# 3. 进度（Progress）
POST /progress/{role}               → 更新自己角色的状态
  body: {status, current_task, completed: [...], pending: [...]}
GET  /progress                      → 全角色进度

# 4. 答案（Answers，仅主设计师可写）
POST /answers                       → 主设计师维护
  body: {category, qid, question, answer, source_role, evidence}
GET  /answers                       → 全量答案表
GET  /answers/{category}            → 按板块

# 5. 跨角色提问（Questions）
POST /questions                     → 角色提问
  body: {from, to, question}
GET  /questions?to=mobile           → 收件箱
POST /questions/{id}/reply          → 回复

# 6. 会话恢复（v3 新增）
GET  /session                       → session_log + blockers + strategy
POST /session/log                   → 主设计师写决策日志
POST /session/blocker               → 角色报告卡点
POST /session/strategy              → 主设计师更新策略

# 7. 文件镜像（可选，远程机要看本机的 role_prompt）
GET  /files/role_prompt_{role}.md   → 静态文件下发
```

### 客户端 CLI（远程机用）

```bash
# 一行 curl 就能用，不需要装 collab_hub.py
curl http://192.168.1.10:8765/ping

# 提交发现（最常用）
curl -X POST http://192.168.1.10:8765/findings -H "Content-Type: application/json" -d '{
  "from": "computer_analyst",
  "summary": "OS版本=Win10 19045",
  "detail": "源: SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"
}'

# 看其他角色进度
curl http://192.168.1.10:8765/progress

# 看主设计师答案表
curl http://192.168.1.10:8765/answers
```

### 离线/局域网部署

```
场景 A：办公室局域网
  [路由器] - 主机 (192.168.1.10:8765) ← 远程机 (192.168.1.11/12)

场景 B：完全离线（比赛断网）
  [手机热点] - 主机 (192.168.43.1:8765) ← 远程机连同一热点

场景 C：极端无路由器
  [网线直连] - 主机 (169.254.1.1) ← 远程机自动 APIPA
```

---

## 4. 会话恢复机制（v3 新增）

**核心思路**：把"上下文"也写进 `shared/`，新会话来时主设计师 `GET /session` 就能恢复。

### `shared/session_log.yaml`
```yaml
# 主设计师每次决策都写一条
- time: "2026-05-07 14:30"
  decision: "决定放弃 GitHub，转 HTTP Hub"
  reason: "hosts 屏蔽 + AI 不会主动 push"
  context_hash: "abc123"  # 用于跨会话识别

- time: "2026-05-07 15:00"
  decision: "Computer 角色卡在 BitLocker，让 Server 角色帮忙找密钥"
  reason: "Computer 找到 BitLocker 加密分区但无密钥"
  related_findings: [F-C003, F-S005]
```

### `shared/blockers.yaml`
```yaml
# 角色报告卡点，主设计师看到后路由
- id: B001
  time: "2026-05-07 14:45"
  from: computer_analyst
  blocker: "BitLocker 加密分区无法打开"
  needs: "BitLocker 密钥或恢复密码"
  status: open  # open / routed / resolved
  routed_to: server_analyst  # 主设计师标注
```

### `shared/strategy.yaml`
```yaml
# 主设计师当前策略
current_phase: "Phase 2 - 平行解题"
priorities:
  - "板块1 计算机取证（基础题，先做完）"
  - "板块5 服务器（关键，影响板块6）"
deferred:
  - "板块4 云手机（需启动 VM，环境复杂）"
notes: |
  Computer 进度快，让它先扫一遍简单题。
  Server 优先恢复 LVM 让 Web 板块能跑。
```

### 跨会话恢复流程

```
新会话启动：
1. 用户说 "继续做 2026FIC 协作"
2. Cascade 读 prompts/main.md → 进入 Main 模式
3. Cascade 调 GET /session → 拿到 session_log + blockers + strategy
4. Cascade 调 GET /progress → 看每个角色当前状态
5. Cascade 调 GET /findings → 拿全部发现
6. Cascade 输出当前态势 + 下一步建议给用户
```

---

## 5. 实现优先级 + 工作清单

### Phase 1：核心 Hub（4 小时）
- [ ] 写 `tools/collab_hub.py`（stdlib `http.server`，单文件 < 500 行）
- [ ] 实现 7 大 API（ping/findings/progress/answers/questions/session/files）
- [ ] 文件锁（避免多角色同时写 findings.yaml 冲突）
- [ ] 启动脚本：`python tools/collab_hub.py serve <case_dir>`

### Phase 2：客户端封装（2 小时）
- [ ] 写 `tools/collab_client.py`（远程机用，stdlib only，便于复制）
- [ ] 命令：`post-finding` / `get-progress` / `report-blocker` / `ask-question`
- [ ] 输出复制到 README 给远程机用

### Phase 3：Prompt 改造（2 小时）
- [ ] 更新 `prompts/roles/*.md` 把 curl 协作流程嵌入每个步骤
- [ ] 关键改动：每解一题 **必须** 调 `POST /findings`，否则视为未完成
- [ ] 主设计师 prompt（`prompts/main.md`）改为先 `GET /session` 恢复上下文

### Phase 4：联调测试（2 小时）
- [ ] 本机启动 Hub
- [ ] 让本机两个角色（server/binary）通过 HTTP 提交一条假发现
- [ ] 远程机用 curl 测试 ping/post/get
- [ ] 模拟跨会话：关 Hub，重启，验证状态恢复

---

## 6. 已有资产（直接复用）

### 现有 `case/` 工作区
位置：`E:\ffffff-JIANCAI\2026FIC团体赛\case\`

```
case/
├── shared/
│   ├── findings.yaml    ← 空
│   ├── progress.yaml    ← 已初始化 4 角色 pending
│   ├── answers.yaml     ← 空模板
│   ├── questions.yaml   ← 空
│   └── timeline.yaml    ← 空
├── role_prompt_computer.md  ← 已生成（但未嵌入协作 curl）
├── role_prompt_mobile.md
├── role_prompt_server.md
├── role_prompt_binary.md
├── collab_setup_*.md         ← v2 Git 方案的部署脚本（v3 实现后可删除）
├── computer/  mobile/  server/  binary/  ← 角色工作目录
│   server/   ← 已有 6 个分析脚本（LVM/LUKS/extent）
│   binary/   ← 已有 SampleVC.exe + r2 分析输出
```

**保留**：`shared/*.yaml`、`role_prompt_*.md`、各角色工作目录
**删除**：`collab_setup_*.md`、`.git/`、GitHub 相关一切

### 现有 `tools/collab_sync.py`
位置：`e:\项目\自动化取证\tools\collab_sync.py`

**保留**：`load_yaml` / `save_yaml` / `shared_dir` 等工具函数
**删除**：所有 `cmd_git_*` 函数、`gh-create` 函数
**重构**：`cmd_lan_serve` → 升级为完整 REST API（即新的 `collab_hub.py`）

---

## 7. 关键决策记录（必读）

### 用户偏好
1. **简体中文对话**，代码注释英文
2. **Karpathy 准则**：先思考再写、简单优先、外科手术式修改、目标驱动执行
3. **报告必带 Excel**：用 openpyxl 生成 .xlsx，含题号/题目/答案/解析/证据/独立解出标记
4. **长任务后台执行**：绝不卡住等结果
5. **决策前问用户**：不要自作主张，多个方案先列出来让用户选

### 设计原则
1. **零依赖**：客户端只需 `curl` 或 `stdlib http.client`
2. **零认证**：局域网/直连环境，不需要 GitHub/SSH 配置
3. **单文件**：Hub 和 Client 各自单文件，便于复制到远程机
4. **持久化优先**：状态全部落到 yaml 文件，Hub 是无状态代理
5. **会话恢复**：通过 `session_log.yaml` 实现"上次说到哪就从哪继续"

### 不做的事
- ❌ 不上 GitHub（hosts 屏蔽 + 认证墙）
- ❌ 不引入 CrewAI/LangGraph/AutoGen（IDE 内 AI 用不了）
- ❌ 不实现 A2A 完整协议（太重，我们的需求只是文件级共享）
- ❌ 不做 SMB 共享（虽然简单但跨网段/防火墙问题多）
- ❌ 不做加密/认证（局域网信任环境，加上反而拖慢调试）

---

## 8. 接手后第一步该做什么

```bash
# 1. 读这份文档（你已经在读了）

# 2. 读上一版的实现，知道哪些可以复用
cat e:\项目\自动化取证\tools\collab_sync.py

# 3. 看现有 case 状态
ls "E:\ffffff-JIANCAI\2026FIC团体赛\case\shared\"
cat "E:\ffffff-JIANCAI\2026FIC团体赛\case\shared\progress.yaml"

# 4. 跟用户确认：
#    "我看了 HANDOFF_COLLAB_V3.md，准备开始 Phase 1 写 collab_hub.py，对吗？"

# 5. 如果用户确认：
#    新建 e:\项目\自动化取证\tools\collab_hub.py
#    用 stdlib http.server 实现 7 个 API
#    保持单文件 < 500 行
```

---

## 9. 联系点

- **现存对话上下文** → trajectory_search 可查
- **项目级 HANDOFF.md** → 项目根目录，2024FIC 训练相关
- **本文档** → 远程协作架构 v3 专属
- **memory 系统** → 用户的全局规则、踩坑记录、工具状态都在 memory 里

---

**END OF HANDOFF v3 — 祝下一个 AI 实现顺利。**
