# ForensicAI — 系统设计文档

**版本**: v0.1-draft
**日期**: 2026-04-27
**状态**: 设计讨论稿，待确认后进入实施

---

## 1. 设计原则

以下六条原则按优先级排列，所有设计决策必须满足高优先级原则后才考虑低优先级：

| # | 原则 | 含义 |
|---|------|------|
| P0 | **离线优先 (Offline-First)** | 断网/隔离网络下仍能运行是核心卖点。所有功能必须有离线方案 |
| P1 | **模型无关 (Model-Agnostic)** | 不绑定 Claude/GPT/DeepSeek 任一模型。强模型跑高级策略，弱模型跑确定性脚本 |
| P2 | **Agent 无关 (Agent-Agnostic)** | 不绑定 Windsurf/Cursor/Claude Code。知识层存在纯 Markdown 文件中，任何 agent 可消费 |
| P3 | **训练产出 > 运行时推理** | 用强模型"平时训练"产出的知识，比"比赛时实时推理"更有价值、更可靠 |
| P4 | **人机共生 (Human-AI Symbiosis)** | AI 辅助人，人校验 AI。纯 AI 自动化和纯人工取证都是本系统的子集 |
| P5 | **教育内嵌 (Education-Native)** | 教育不是附加模块，而是知识库的天然副产品 |

---

## 2. 总体架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户层 (Human)                           │
│  比赛选手 / 培训学员 / 取证工程师                                 │
└──────────┬──────────────────────────────────┬───────────────────┘
           │                                  │
     ┌─────▼─────┐                     ┌──────▼──────┐
     │  模式控制  │                     │  教育交互   │
     │ (Session   │                     │ (Tutor      │
     │  Router)   │                     │  Engine)    │
     └─────┬─────┘                     └──────┬──────┘
           │                                  │
     ┌─────▼──────────────────────────────────▼───────────────┐
     │                   Agent 适配层                          │
     │                                                        │
     │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
     │  │ Windsurf │ │  Cursor  │ │ Claude   │ │ OpenClaw │  │
     │  │ Adapter  │ │ Adapter  │ │ Code     │ │ /其他    │  │
     │  │(.windsurf│ │(.cursor  │ │Adapter   │ │Adapter   │  │
     │  │ rules)   │ │ rules)   │ │(CLAUDE.md│ │(AGENTS.md│  │
     │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │
     │       └─────┬───────┴──────┬─────┘            │        │
     │             │              │                   │        │
     └─────────────┼──────────────┼───────────────────┘        │
                   │              │                             │
     ┌─────────────▼──────────────▼─────────────────────────┐  │
     │                知识内核 (Knowledge Core)               │  │
     │                                                       │  │
     │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │  │
     │  │  题库         │ │  工具库       │ │  策略库       │  │  │
     │  │ (Solved DB)  │ │ (Tool        │ │ (Strategy    │  │  │
     │  │              │ │  Registry)   │ │  Profiles)   │  │  │
     │  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘  │  │
     │         └────────┬───────┴────────┬───────┘          │  │
     │                  │                │                   │  │
     │         ┌────────▼─────┐  ┌───────▼────────┐         │  │
     │         │  双模式索引   │  │  验证引擎       │         │  │
     │         │ (Dual Index) │  │ (Verifier)     │         │  │
     │         │ A: RAG向量   │  │ - 格式校验      │         │  │
     │         │ B: 确定性SOP │  │ - 交叉验证      │         │  │
     │         └──────────────┘  └────────────────┘         │  │
     └──────────────────────────────────────────────────────┘  │
                                                               │
     ┌─────────────────────────────────────────────────────────┘
     │
     ▼
┌────────────────────────────────────────────────────────────────┐
│                    模型层 (Model Layer)                         │
│                                                                │
│  方案 A: 云端 API        方案 B: 本地部署        方案 C: 混合   │
│  Claude/GPT/DeepSeek    Ollama/vLLM             A做训练,B做执行 │
│  API                    + 本地 embedding                       │
│                         + FAISS                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. 知识内核设计

### 3.1 题库 (Solved DB)

每道已解题目一个 YAML 文件，存放于 `knowledge/solved/<比赛ID>/Q<NN>.yaml`。

**完整 Schema:**

```yaml
# === 元数据 ===
meta:
  competition: "FIC2026"              # 比赛名称
  competition_id: "2026fic"           # 比赛唯一ID (用于路径和索引)
  question_id: "C01"                  # 题号
  question_text: |                    # 题目原文 (一字不改)
    请分析嫌疑人电脑，获取其IP地址
  category_l1: "windows_disk"         # 一级分类 (证据类型)
  category_l2: "network_config"       # 二级分类 (知识点)
  tags:                               # 自由标签 (可扩展)
    - "registry_analysis"
    - "ip_extraction"
    - "dhcp"
  points: 5                           # 分值
  difficulty: "easy"                  # easy / medium / hard / expert

# === 答案 ===
answer:
  value: "192.168.1.100"              # 答案值
  value_type: "ip_address"            # 值类型: ip_address/hash/date/path/text/number
  confidence: "high"                  # high / medium / low
  verified: true                      # 是否经过验证
  verified_method: "official_answer"  # official_answer / cross_validate / manual_check / unverified
  verified_date: "2026-04-27"

# === 解题过程 (人工可复现级) ===
walkthrough:
  summary: "从注册表 SYSTEM hive 提取 DHCP 配置的 IP 地址"
  steps:
    - seq: 1
      description: "定位并导出 SYSTEM 注册表 hive"
      command: "RECmd.exe --hive {evidence}/Windows/System32/config/SYSTEM -o output.csv"
      tool: "RECmd"
      expected_output: "生成 output.csv，约数千行"
      human_note: "如果检材是 E01 镜像，需先挂载后找到 SYSTEM 文件"

    - seq: 2
      description: "在输出中搜索网络配置"
      command: "grep -i 'IPAddress\\|DhcpIPAddress' output.csv"
      tool: "grep"
      expected_output: "包含 192.168.x.x 格式的 IP"
      human_note: "注意区分多网卡，检查 DefaultGateway 判断主网卡"

    - seq: 3
      description: "交叉验证"
      command: "grep -i 'SubnetMask\\|DefaultGateway' output.csv"
      tool: "grep"
      expected_output: "网关和子网掩码应与 IP 在同一网段"
      human_note: "如果网关是 192.168.1.1，那么 IP 192.168.1.100 合理"

  evidence_path: "PC.E01 → [root]/Windows/System32/config/SYSTEM"

# === 工具信息 ===
tools_used:
  - name: "RECmd"
    version: "2.0+"
    platform: "windows"               # windows / linux / both
    install_script: "install/02_install_win_tools.ps1"
    install_path: "C:\\Tools\\ZimmermanTools\\RECmd.exe"
    alternative: "regipy (Python, Linux)"  # 替代工具

# === AI 元数据 ===
ai_meta:
  first_solved_by: "claude-sonnet-4"  # 首次解出使用的模型
  solve_time_seconds: 45              # AI 解题耗时
  token_cost_usd: 0.15                # 估算 token 成本
  model_difficulty: "trivial"         # 对 AI 的难度: trivial/easy/medium/hard/unsolved
  requires_gui: false                 # 是否需要 GUI 操作
  requires_internet: false            # 是否需要联网

# === 教育元数据 ===
education:
  prerequisites:
    - "Windows 注册表基础结构"
    - "TCP/IP 网络基础 (IP/子网掩码/网关)"
  learning_objectives:
    - "掌握 RECmd 工具的基本使用"
    - "理解 Windows 网络配置在注册表中的存储位置"
    - "学会通过交叉验证确认取证结论"
  difficulty_for_human: "beginner"
  estimated_learning_time: "15min"
  guided_prompts:
    - prompt: "这道题问 IP 地址。在 Windows 系统中，网络配置通常存储在哪里？"
      hints:
        - "想想 Windows 的五大注册表 hive"
        - "SYSTEM hive 存储系统和硬件配置"
      answer_keywords: ["注册表", "SYSTEM", "registry"]
    - prompt: "请用工具导出 SYSTEM hive 并搜索网络相关键值，你找到了什么？"
      hints:
        - "搜索 DhcpIPAddress 或 IPAddress"
      answer_keywords: ["192.168"]
    - prompt: "你找到的 IP 是否合理？如何验证？"
      hints:
        - "检查网关地址是否在同一子网"
  common_mistakes:
    - mistake: "只看 DHCP 地址，忽略静态 IP 配置"
      correction: "检查 EnableDHCP 值，0=静态 1=DHCP"
    - mistake: "找到多个网卡 IP 不知道选哪个"
      correction: "有 DefaultGateway 的网卡通常是主网卡"
  related_questions:
    - "2026fic/C02"  # 关联题目
  knowledge_refs:
    - "knowledge/windows/registry_forensics.md"

# === 状态追踪 ===
status:
  progress: "complete"                # draft / in_progress / complete / needs_review
  human_reviewed: true
  last_updated: "2026-04-27"
  notes: ""
```

### 3.2 取证知识分类标签体系

采用两级分类 + 自由标签。两级分类是固定框架，自由标签可无限扩展。

```yaml
# knowledge/taxonomy.yaml
taxonomy:
  windows_disk:
    display_name: "Windows 磁盘/镜像"
    subcategories:
      - registry_analysis        # 注册表分析
      - event_log               # 事件日志
      - browser_history         # 浏览器历史
      - file_recovery           # 文件恢复/删除文件
      - file_system             # 文件系统 (MFT/NTFS)
      - timeline_analysis       # 时间线分析
      - encryption_detection    # 加密检测 (BitLocker/VeraCrypt)
      - email_client            # 邮件客户端 (Outlook/Foxmail/Thunderbird)
      - user_activity           # 用户行为 (Shellbags/Prefetch/JumpList)
      - network_config          # 网络配置
      - usb_device              # USB 设备痕迹
      - installed_software      # 已安装软件
      - cloud_storage           # 云盘/同步工具
      - virtual_machine         # 虚拟机检测

  linux_server:
    display_name: "Linux 服务器"
    subcategories:
      - log_analysis            # 系统日志 (/var/log)
      - web_log                 # Web 服务器日志
      - database_forensics      # 数据库取证 (MySQL/TiDB/Redis)
      - docker_container        # Docker/容器取证
      - webshell_detection      # WebShell 检测
      - intrusion_timeline      # 入侵时间线
      - crontab_analysis        # 定时任务分析
      - ssh_analysis            # SSH 登录分析
      - process_memory          # 进程/内存分析

  mobile_android:
    display_name: "Android 手机"
    subcategories:
      - app_data_extraction     # App 数据提取
      - wechat_analysis         # 微信分析
      - qq_analysis             # QQ 分析
      - call_sms_contacts       # 通话/短信/联系人
      - gps_location            # GPS/位置信息
      - photo_video             # 图片/视频/EXIF
      - apk_reverse             # APK 逆向
      - browser_mobile          # 移动浏览器
      - wallet_crypto           # 数字钱包/加密货币
      - social_media            # 社交媒体 (抖音/微博/小红书)

  mobile_ios:
    display_name: "iOS 手机"
    subcategories:
      - itunes_backup           # iTunes 备份解析
      - keychain                # Keychain 提取
      - health_data             # 健康数据
      - imessage                # iMessage

  network_traffic:
    display_name: "网络流量"
    subcategories:
      - protocol_analysis       # 协议分析
      - file_carving            # 文件提取 (从流量中)
      - encrypted_traffic       # 加密流量 (TLS/VPN)
      - dns_analysis            # DNS 分析
      - email_protocol          # 邮件协议 (SMTP/POP3/IMAP)
      - voip_analysis           # VoIP/音视频通话
      - malware_traffic         # 恶意流量特征

  binary_reverse:
    display_name: "二进制/逆向"
    subcategories:
      - password_cracking       # 密码破解
      - algorithm_identification # 算法识别
      - anti_debug              # 反调试/反混淆
      - crypto_implementation   # 加密算法实现
      - malware_analysis        # 恶意软件分析
      - firmware_analysis       # 固件分析

  osint:
    display_name: "开源情报"
    subcategories:
      - social_media_osint      # 社交媒体调查
      - domain_whois            # 域名/Whois
      - image_metadata          # 图片元数据
      - geolocation             # 地理定位
      - dark_web                # 暗网调查

  iot_drone:
    display_name: "IoT/无人机"
    subcategories:
      - drone_flight_log        # 无人机飞行日志
      - smart_device            # 智能设备
      - vehicle_forensics       # 车载取证
```

### 3.3 工具注册表 (Tool Registry)

```yaml
# knowledge/tools/RECmd.yaml
tool:
  name: "RECmd"
  display_name: "Registry Explorer Command Line"
  category: "registry"
  vendor: "Eric Zimmerman"
  platforms:
    windows:
      install_method: "download"
      install_command: "Invoke-WebRequest -Uri 'https://...' -OutFile RECmd.zip"
      install_path: "C:\\Tools\\ZimmermanTools\\RECmd.exe"
      version: "2.0+"
    linux:
      alternative: "regipy"
      install_method: "pip"
      install_command: "pip install regipy"

  use_cases:
    - "注册表 hive 批量导出为 CSV"
    - "搜索特定注册表键值"
    - "时间线分析"

  common_commands:
    - description: "导出整个 SYSTEM hive"
      command: "RECmd.exe --hive SYSTEM -o output.csv"
    - description: "搜索特定键"
      command: "RECmd.exe --hive NTUSER.DAT --kn 'Software\\Microsoft' -o output.csv"

  related_tools:
    - "Registry Explorer (GUI版)"
    - "regipy (Python替代)"

  tested_in_competitions:
    - competition: "2026fic"
      used_for: ["C01", "C02", "C05", "C06", "C07"]
      effectiveness: "high"
```

### 3.4 双模式索引

#### 模式 A: RAG 向量检索 (需 embedding 模型)

```
适用场景: 有一定推理能力的模型 (Claude/GPT/DeepSeek-V3/Qwen3-32B+)

工作流:
1. 读题 → embedding → FAISS 检索 top-5 相似已解题
2. 把检索结果作为 context 注入 prompt
3. 模型基于 context + 推理能力生成解题方案

依赖:
- embedding 模型: bge-small-zh-v1.5 (~100MB, CPU 可跑)
- FAISS 向量库: 从 knowledge/solved/ 生成
- 不抢 LLM 推理算力，额外开销极小

离线方案:
- embedding 模型和 FAISS 索引预先构建好
- 完全离线可用
```

#### 模式 B: 确定性 SOP 脚本 (无需 LLM 推理)

```
适用场景: 极低性能模型 / 纯人工 / 严格离线

工作流:
1. 读题 → 关键词匹配 → 匹配 category_l1 + category_l2
2. 查找对应的 SOP 脚本: knowledge/sop/<l1>/<l2>.md
3. SOP 脚本是确定性的: "执行命令X → 解析输出Y → 填入答案Z"
4. 低性能模型只需要做模板填充

SOP 脚本示例 (knowledge/sop/windows_disk/network_config.md):
─────────────────────────────
## 场景: 提取 Windows 网络配置

### 前置条件
- 已挂载 Windows 镜像或可访问 SYSTEM hive

### 步骤
1. 定位 SYSTEM hive: `find {mount} -name "SYSTEM" -path "*/config/*"`
2. 导出: `RECmd.exe --hive {SYSTEM_PATH} -o net_config.csv`
   - Linux替代: `python -c "from regipy.registry import RegistryHive; ..."`
3. 提取 IP: `grep -i 'DhcpIPAddress\|IPAddress' net_config.csv | head -20`
4. 提取网关: `grep -i 'DefaultGateway' net_config.csv`
5. 验证: IP 和网关应在同一子网

### 输出模板
答案: {提取到的IP地址}
证据: {SYSTEM hive 路径}
验证: 网关 {网关地址} 与 IP 在同一 /{子网掩码位数} 子网
─────────────────────────────

优势:
- 7B 模型甚至纯人工都可以执行
- 不依赖任何 AI 推理能力
- 完全离线
- 可以批量生成 (一个 SOP 覆盖一类题)
```

#### 模式选择逻辑

```python
# 伪代码
def select_index_mode(model_capability, network_status):
    if network_status == "airgapped" and model_capability == "low":
        return "mode_b_sop"       # 确定性脚本
    elif model_capability in ["high", "medium"]:
        return "mode_a_rag"       # RAG 向量检索
    else:
        return "mode_b_sop"       # 兜底用确定性脚本
```

---

## 4. 模式矩阵与策略切换

### 4.1 运行模式矩阵

```yaml
# 会话开始时确定以下维度:
session:
  network: online | lan_only | airgapped    # 网络环境
  model: cloud_api | local_high | local_low  # AI 模型
  scenario: competition | training | review | education  # 场景
  integrity: exam_mode | unrestricted       # 诚信模式
  collaboration: solo | pair | team         # 协作模式
  platform: windows | linux | wsl           # 运行平台
```

### 4.2 策略配置文件

每种组合有对应策略，存放于 `strategies/` 目录：

```
strategies/
├─ competition_cloud_solo.yaml      # 线上比赛 + 云端模型 + 单人
├─ competition_local_team.yaml      # 线下比赛 + 本地模型 + 团队
├─ competition_airgap_pair.yaml     # 断网比赛 + 本地模型 + 双人
├─ training_cloud_solo.yaml         # 训练模式 + 云端模型 (产出知识)
├─ training_exam_cloud.yaml         # 训练测试 + 禁搜答案
├─ education_local_solo.yaml        # 教学模式 + 本地模型
└─ review_cloud_solo.yaml           # 复盘模式
```

**策略文件示例:**

```yaml
# strategies/competition_airgap_pair.yaml
name: "断网线下比赛 (双人协作)"
description: "适用于有局域网但无互联网的线下比赛"

model_config:
  primary: "ollama/qwen3-32b"       # 主力模型
  embedding: "bge-small-zh-v1.5"    # embedding (预装)
  fallback: "ollama/qwen3-7b"       # 备用轻量模型

index_mode: "mode_a_rag"            # 32B 模型够用 RAG

agent_config:
  max_time_per_question: 20         # 分钟
  skip_after: 30                    # 分钟后跳题
  verification: "self_check"        # 自检模式
  parallel_agents: 2                # 两台电脑并行

human_role:
  triage: true                      # 人类负责分桶
  verification_interval: 10         # 每 10 题人工检查一次
  gui_tools: true                   # 人类操作火眼/取证大师等 GUI

constraints:
  no_internet_search: true          # 禁止联网搜索
  no_external_api: true             # 禁止调用外部 API
  local_only: true                  # 仅使用本地资源
```

### 4.3 防作弊机制 (exam_mode)

```yaml
# 在 exam_mode 下注入的硬规则
exam_mode:
  forbidden_actions:
    - "搜索 {competition_name} {year} 的 writeup 或答案"
    - "搜索题目原文以获取他人解答"
    - "访问任何包含该比赛答案的网址"
  allowed_actions:
    - "搜索工具使用方法"
    - "搜索技术概念解释"
    - "查阅本地知识库"
  integrity_log: "worklog/exam_integrity.log"  # 记录所有搜索行为
```

---

## 5. Agent 适配层

### 5.1 Single Source of Truth 架构

```
project/
├─ AGENTS.md                    ← 通用入口 (所有 agent 都读)
├─ .windsurf/rules/
│   └─ project-rules.md         ← "请先读 AGENTS.md" + Windsurf 特有规则
├─ .cursorrules                 ← "请先读 AGENTS.md" + Cursor 特有规则
├─ CLAUDE.md                    ← "请先读 AGENTS.md" + Claude Code 特有规则
├─ .github/copilot-instructions.md ← "请先读 AGENTS.md"
│
├─ AI_BRAIN/                    ← Agent 无关的知识层 (纯 Markdown)
│   ├─ persona.md               # AI 行为定义
│   ├─ output_contract.md       # 输出格式契约
│   ├─ tool_inventory.md        # 工具清单
│   └─ solved_patterns/         # 已验证解法模式
│
├─ knowledge/                   ← Agent 无关的知识库
│   ├─ solved/                  # 题库 (YAML)
│   ├─ taxonomy.yaml            # 分类标签体系
│   ├─ tools/                   # 工具注册表
│   ├─ sop/                     # 确定性 SOP 脚本
│   └─ rag_index/               # 预构建的 FAISS 索引
│
└─ strategies/                  ← Agent 无关的策略配置
```

### 5.2 AGENTS.md 内容 (通用入口)

```markdown
# ForensicAI — AI Agent 入口

你是一个电子数据取证助手。请按以下顺序读取项目文件：

1. 读 `AI_BRAIN/persona.md` — 了解你的角色和行为规范
2. 读 `AI_BRAIN/output_contract.md` — 了解答案输出格式要求
3. 询问用户当前的运行模式 (比赛/训练/教学/复盘)
4. 根据模式加载对应策略文件 `strategies/*.yaml`
5. 开始工作

## 核心规则
- 始终使用简体中文
- 每道题的答案必须包含 5 个字段 (见 output_contract.md)
- 遇到不确定的情况，停下来问用户
- 不修改 evidence/ 目录下的任何文件
```

---

## 6. 教育模式设计

### 6.1 三级教学

| 级别 | 名称 | AI 角色 | 适用对象 |
|------|------|---------|---------|
| L1 | 手把手 (Guided) | 苏格拉底式引导，逐步提问 | 零基础新手 |
| L2 | 提示 (Hinted) | 给方向提示，学生自主操作 | 有一定基础 |
| L3 | 独立 (Independent) | 只提供题目，解完后点评 | 备赛选手 |

### 6.2 教学引擎逻辑

```
教育模式工作流:
1. 加载 Q[NN].yaml 中的 education 字段
2. 根据学生级别选择引导方式:
   - L1: 逐步展示 guided_prompts，等待学生回答
   - L2: 只给 prerequisites 和 learning_objectives，学生自行探索
   - L3: 只给题目，学生解完后对比 walkthrough
3. 学生回答后:
   - 正确 → 给予确认 + 深入解释
   - 错误 → 展示 common_mistakes 中的对应项
   - 卡住 → 逐级释放 hints
4. 完成后:
   - 总结学到了什么 (learning_objectives)
   - 推荐下一道题 (related_questions)
```

### 6.3 学习路径自动生成

基于 `knowledge/solved/` 中所有已解题目，按 `difficulty_for_human` 和 `prerequisites` 依赖关系自动生成学习路线：

```
自动生成算法:
1. 遍历所有 Q[NN].yaml
2. 构建依赖图 (prerequisites → learning_objectives)
3. 拓扑排序得到学习顺序
4. 按 category_l1 分组
5. 每组内按 difficulty_for_human 排序
6. 输出为 education/learning_path.md
```

### 6.4 教学模式与低性能模型的天然契合

教学模式是**低性能模型最理想的应用场景**：
- 对话脚本是预写好的 (guided_prompts)
- 模型只需做简单的关键词匹配和模板响应
- 不需要长链推理或工具链串联
- 7B 参数量的模型即可胜任

---

## 7. 协作与共享机制

### 7.1 知识同步架构

```
公共仓库 (GitHub/Gitee)          私有仓库 (本地/团队)
├─ knowledge/                    ├─ knowledge/
│   ├─ solved/ (公开题解)        │   ├─ solved/ (含敏感题解)
│   ├─ taxonomy.yaml             │   ├─ private_cases/
│   ├─ tools/                    │   └─ team_notes/
│   └─ sop/                     │
├─ AI_BRAIN/ (通用版)            ├─ AI_BRAIN/ (定制版)
├─ strategies/                   ├─ strategies/
├─ install/                      └─ .env (API keys等)
└─ education/
```

### 7.2 贡献流程

```
贡献者用强模型做题
       │
       ▼
  产出 Q[NN].yaml
       │
       ▼
  提交 PR 到公共仓库
       │
       ▼
  维护者审核 (质量 + 格式)
       │
       ▼
  合并 → 自动重建 RAG 索引
       │
       ▼
  所有用户 git pull 获得最新知识
```

### 7.3 敏感内容处理

```yaml
# .gitignore 中排除敏感内容
knowledge/solved/*/Q*.yaml  # 默认不提交
knowledge/solved/public/    # 显式标记为公开的才提交

# 每个题解可标记公开级别
meta:
  visibility: "public"      # public / team_only / private
```

---

## 8. 安全与对抗准备

### 8.1 数据投毒防护

```
风险: 恶意用户提交错误的 Q[NN].yaml 污染知识库

防护措施:
1. verified_method 字段区分来源可信度
   - official_answer > cross_validate > manual_check > unverified
2. 公共仓库的 PR 需要维护者审核
3. AI 使用知识时优先采信高可信度来源
4. 定期用已知答案回归测试知识库准确率
```

### 8.2 离线环境安全

```
风险: 本地模型被替换/篡改

防护措施:
1. 模型文件 SHA256 校验和预存于 install/checksums.txt
2. 启动时自动校验模型完整性
3. 工具链同样做哈希校验
```

---

## 9. 平台与工具策略

### 9.1 推荐运行平台

| 优先级 | 平台 | 场景 | 理由 |
|--------|------|------|------|
| 1 | **Linux 原生** | 本地模型 + 服务器部署 | 取证工具最全、vLLM/Ollama 原生支持 |
| 2 | **WSL2** | Windows 主机 + 比赛现场 | 兼顾 Windows GUI 工具和 Linux 命令行 |
| 3 | **Windows 原生** | 仅使用 GUI 取证工具时 | 火眼/取证大师等只有 Windows 版 |

### 9.2 工具安装自动化

```
install/
├─ 00_diagnose.sh               # 环境诊断 (跨平台)
├─ 01_install_linux_tools.sh     # Linux 取证工具
├─ 02_install_python_env.sh      # Python venv + 依赖
├─ 03_install_local_model.sh     # Ollama + 模型下载
├─ 04_build_rag_index.py         # 构建 FAISS 向量索引
├─ 05_verify_all.sh              # 全部工具验证
├─ checksums.txt                 # 所有工具/模型的 SHA256
└─ offline_bundle/               # 离线安装包 (预下载)
    ├─ ollama-linux-amd64.tar
    ├─ qwen3-32b-q4.gguf
    ├─ bge-small-zh-v1.5/
    └─ tools/*.deb
```

---

## 10. 进度追踪与版本管理

### 10.1 项目状态仪表盘

```bash
# 一键查看项目状态
python scripts/status.py

输出示例:
═══════════════════════════════════════
  ForensicAI 项目状态    v0.3.0
═══════════════════════════════════════
  知识库:
    已解题目:  87 / ~200 (预估总题池)
    已验证:    62 (71.3%)
    待审核:    12
    覆盖比赛:  FIC2026, 平航杯2025, 盘古石2025
  
  工具链:
    已注册工具: 34
    已测试:     28 (82.4%)
    
  SOP 脚本:
    已编写:    23 / 38 (分类总数)
    覆盖率:    60.5%
    
  RAG 索引:
    最后更新:  2026-04-25
    向量数:    487
    
  教育路径:
    已编写引导: 42 题
    学习路线:   3 条 (入门/进阶/竞赛)
═══════════════════════════════════════
```

### 10.2 版本管理

```
CHANGELOG.md — 记录每个版本的变更
语义版本号: vMAJOR.MINOR.PATCH

MAJOR: 架构变更 (如引入新的模式)
MINOR: 功能新增 (如新增一批题解/新增教育路径)
PATCH: 修复和优化 (如修正错误答案/优化 SOP)
```

---

## 11. 实施路线图

### Phase 0: 基础重构 (1-2 周)

- [ ] 建立新目录结构 (`knowledge/solved/`, `strategies/`, `install/`)
- [ ] 创建 AGENTS.md 通用入口
- [ ] 迁移现有 FIC2026 题解到 YAML 格式
- [ ] 编写 taxonomy.yaml 分类标签体系
- [ ] 验证: 至少 5 道题完整填写所有字段

### Phase 1: 知识引擎 (2-3 周)

- [ ] 实现 RAG 模式 A (FAISS + bge-small-zh embedding)
- [ ] 编写 10 个核心 SOP 脚本 (模式 B)
- [ ] 工具注册表初始化 (覆盖 20+ 工具)
- [ ] 验证: 用 RAG 检索 FIC2026 题目，命中率 > 80%

### Phase 2: 多模型支持 (2-3 周)

- [ ] Ollama 本地部署 + 测试 (Qwen3-32B / DeepSeek-V3-0324)
- [ ] 离线 embedding 模型部署
- [ ] 策略文件编写 (至少 3 种场景)
- [ ] 模式选择路由逻辑
- [ ] 验证: 本地 32B 模型 + RAG 能解出 FIC2026 中至少 20 道题

### Phase 3: 教育模式 (2-4 周)

- [ ] 编写 20 道题的 education 字段 (guided_prompts)
- [ ] 实现教学引擎原型
- [ ] 生成第一条学习路径 ("Windows 取证入门")
- [ ] 验证: 找一个零基础用户完成入门路径

### Phase 4: 协作与部署 (2 周)

- [ ] 公共仓库初始化
- [ ] 贡献指南 (CONTRIBUTING.md)
- [ ] 离线安装包打包脚本
- [ ] CI/CD: PR 合并后自动重建 RAG 索引
- [ ] 验证: 新用户按 README 从零部署成功

---

*本文档为系统设计讨论稿。所有架构决策均基于 FIC2026 实战数据和外部研究。
待用户确认后进入实施阶段。*
