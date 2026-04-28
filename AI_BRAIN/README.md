# AI_BRAIN — AI 持久化大脑

> **项目**: ForensicAI (小空自己动) | **通用入口**: 请先读根目录 `AGENTS.md`

> 任何 AI agent（Windsurf / Cursor / Claude Code / 其他）打开本项目，**先读根目录 `AGENTS.md`**，再读本文件。
>
> **核心目的**：即使换一个模型/账号/新 AI agent，只要读完 AI_BRAIN/ 目录，就能无缝接续工作。
> 
> **本目录的权威性**：所有"我该怎么干活"相关的规则、风格、格式、工具位置、已解题套路，**只在本目录内定义**。其他地方（如 `KARPATHY_GUIDELINES.md`、`WP_FORMAT.md`）是详细补充，以本目录为索引起点。

---

## 📁 本目录结构

```
AI_BRAIN/
├─ README.md                    ← 你正在读的索引
├─ persona.md                   工作风格定义（行为准则）
├─ output_contract.md           答案输出契约（必含字段 + 格式）
├─ tool_inventory.md            工具清单 + 安装位置 + 调用命令
├─ solved_patterns/             已解题的"套路库"（按题型组织）
│  ├─ README.md                    套路库索引
│  ├─ _template.md                 新套路模板
│  ├─ android_wechat_db.md         安卓微信 DB 解密
│  ├─ memory_malware_hunt.md       内存木马定位
│  ├─ spammimic_steg.md            spammimic 隐写解码
│  ├─ lm_studio_model.md           LM Studio 模型识别
│  ├─ mail_attachment_md5.md       邮件附件 MD5
│  ├─ phone_model_fingerprint.md   手机型号指纹
│  └─ dotnet_malware_strings.md    .NET 木马字符串挖掘
└─ session_handoff.md           当前会话的"接力棒"（给下次 AI）
```

---

## 🚀 开场 5 步（换了新 AI 也一样做）

```
1. 读 AI_BRAIN/README.md            ← 本文
2. 读 AI_BRAIN/persona.md           → 知道行为风格
3. 读 AI_BRAIN/output_contract.md   → 知道输出格式
4. 读 AI_BRAIN/session_handoff.md   → 知道上一次到哪了
5. 读 worklog/<最新日期>*.md         → 拿到上次详细进度
```

之后按用户指令开工。遇到新题型，**先查 `solved_patterns/`** 有没有同类套路可复用。

---

## 🔧 用户想修改什么时改哪里？

| 修改什么 | 改哪个文件 |
|---------|----------|
| **我的工作风格**（主动/被动、话多/话少、问不问用户） | `AI_BRAIN/persona.md` |
| **我给答案必含的字段 / 格式** | `AI_BRAIN/output_contract.md` |
| **项目硬规则**（不许动 evidence 等） | `.windsurf/rules/project-rules.md` |
| **WP 批次文件的具体 Markdown 模板** | `WP_FORMAT.md`（被 output_contract 引用） |
| **某类题的解法模板** | `AI_BRAIN/solved_patterns/<题型>.md` |
| **工具装哪、怎么调用** | `AI_BRAIN/tool_inventory.md` |
| **Karpathy 四准则** | `KARPATHY_GUIDELINES.md`（引用 `E:\项目\andrej-karpathy-skills-main`） |

**修改后无需重启**：下次我读规则时即生效。

---

## 📝 我该写什么 / 什么时候写？

### 解出一道新题目 → 套路库更新

若某道题的解法**可复用于同类题**，把它沉淀成一个 `solved_patterns/<题型>.md` 文件。
已有同题型？**追加 variant**，不另起新文件。

### 用到新工具 / 装了新东西 → 工具清单更新

在 `tool_inventory.md` 追加：工具名、版本、安装命令、调用示例、装在哪。

### 卡了很久 / 踩了坑 → 自诊断更新

`worklog/AI_DIAGNOSTICS.md` 追加一个 Pattern，包括：症状、根因、永久修复。

### 会话结束（用户说暂停/晚安）→ 日志 + 接力棒

1. `worklog/YYYY-MM-DD_NN_<主题>.md` 写本次完整日志
2. 更新 `AI_BRAIN/session_handoff.md` — 给下次 AI 用的**一页纸摘要**
3. 更新对应比赛的 `handover.md`（如果是比赛题）

---

## 🎓 自我迭代原则

每次解完题，问自己：
1. **这类题以后还会遇到吗？** → 抽象成 `solved_patterns/`
2. **我踩的坑下次还可能踩？** → 追加 `AI_DIAGNOSTICS.md`
3. **我用的工具之前没记录？** → 补 `tool_inventory.md`
4. **我有好用的命令模板？** → 放到对应 solved_pattern 的"可复现命令"块

**不迭代的代价**：下次 AI（或未来的我）看不到这些教训，重复浪费时间。

---

## 🪪 每次会话进入的"身份声明"（AI 应该主动说）

```
已加载 AI_BRAIN（版本 YYYY-MM-DD）：
- persona: <风格简述>
- output contract: <5 字段强制>
- 已知套路: N 个
- 工具清单: M 条
- 上次会话进度: <一句话>
开始接力。
```

这样用户能**立刻知道**新 AI 的状态是否对齐。

---

## 📍 最后的不变性（"宪法"，非用户要求不修改）

1. **中文对话** - 与用户沟通用简体中文
2. **证据可复现** - 每个答案必须能凭证据链 + 命令重跑
3. **不作弊** - 不访问外部题解、在复现，练习时不使用AI 知识库中的正在做的这个比赛的题目解析作为参考、付费黑盒工具
4. **不假装** - 不知道就说不知道，不编造

这 4 条写死在 `persona.md`，改它们需要用户明确要求。
