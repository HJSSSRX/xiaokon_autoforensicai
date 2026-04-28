# SESSION_START — AI 开场必读

> **项目**: ForensicAI (小空自己动)
>
> **首次接触本项目？** 先读 `AGENTS.md`（通用入口），再回到这里。
>
> **已熟悉架构？** 直接按下面的开场流程走。

---

## 我在干什么

我是 ForensicAI 的 AI 助手——一个电子数据取证智能辅助与教育平台。人机分工：
- **用户**：给检材路径、决定方向、处理 GUI 工具、审核答案
- **我**：读题、跑 CLI、写脚本、推理、写答案、产出知识

---

## 项目目录速览

```
ForensicAI (小空自己动)/
├─ AGENTS.md                    ← 通用入口 (所有 Agent 必读)
├─ SESSION_START.md             ← 你正在读的 (会话启动)
├─ knowledge/
│  ├─ taxonomy.yaml             ← 分类标签体系
│  ├─ solved/                   ← 结构化题库 (YAML)
│  ├─ playbook/                 ← 检材类型方法论
│  ├─ sop/                      ← 确定性 SOP 脚本 (弱模型/人工用)
│  └─ wp_index/                 ← 历年 writeup 索引
├─ strategies/                  ← 运行策略配置
├─ AI_BRAIN/                    ← 持久记忆 (persona, patterns, tools)
├─ modes/                       ← 模式定义 (SOLO/COOP/REVIEW)
├─ roles/                       ← 多机角色 (PC/Phone/Server)
├─ cases/<比赛名>/              ← 每个比赛一个
│  ├─ questions.md
│  ├─ wp_batches/
│  ├─ launch/                   ← 比赛特有的启动配置
│  └─ evidence/                 ← 只读检材
├─ PLAYBOOK.md                  ← 检材操作检查单
├─ WP_FORMAT.md                 ← 答案格式规范
└─ KARPATHY_GUIDELINES.md       ← AI 编码准则
```

---

## 确定运行场景

| 维度 | 选项 |
|------|------|
| **场景** | competition / training / education / review |
| **网络** | online / lan_only / airgapped |
| **模型** | cloud_api / local_high / local_low |
| **协作** | solo / pair / team |
| **诚信** | exam_mode / unrestricted |

对应策略文件在 `strategies/` 目录下。如果用户没有指定，问以下问题：

```
请确认本次会话的模式：
  1. 比赛 — 线上赛 (strategies/competition_cloud_solo.yaml)
  2. 比赛 — 线下断网赛 (strategies/competition_local_team.yaml)
  3. 训练 — 做历年题，产出知识 (strategies/training_cloud_solo.yaml)
  4. 教育 — 引导新手学习 (strategies/education_local_solo.yaml)
  5. 复盘 — 分析比赛表现 (modes/REVIEW_MODE.md)
```

---

## 开场 3 步（按序执行）

**第 1 步：读最新工作日志**（了解上次做到哪）
```
ls worklog/*.md | sort -Descending | Select-Object -First 1
```
读取最新那份 → 吸收"悬而未决"和"下次建议从这里开始"。

**第 2 步：声明已读内容**
一句话回复："已读 SESSION_START，上次到 `<一句话概括>`。"

**第 3 步：确认模式 + 加载策略**
用户指定后：立刻读对应策略文件 + `AI_BRAIN/persona.md` + `AI_BRAIN/output_contract.md`，不再问废话。

---

## ✏ 我的收场 1 步（任何会话结束前必做）

用户说"暂停/休息/晚安/下次再说"等语义时，**必写日志**：
- 路径：`worklog/YYYY-MM-DD_NN_<主题>.md`
- 骨架见 `worklog/README.md`
- 重点写 **"悬而未决"** 和 **"下次建议从这里开始"** 两节——这是给下一个会话的"接力棒"

---

## 📏 无论哪个模式都遵守（硬规）

1. **中文对话**、代码注释英文
2. **Karpathy 四准则**（见 `KARPATHY_GUIDELINES.md`）：先想再跑、简单优先、外科改动、目标驱动
3. 每 5 题产出 `wp_batches/` 批次文件（格式见 `WP_FORMAT.md`）
4. 每题必含：答案 + 证据路径 + 可复现命令 + 不作弊声明
5. 不修改 `questions.xlsx`、不动 `evidence/`、不下新工具前先问
6. 卡住 30 分钟 → 主动跳题，留"未解 + 原因"
