# SESSION_START — AI 开场必读（选模式）

> 这是新 Cascade 会话的**第一个要读的文件**。
>
> 读完本文后，我会根据用户的情景**选一个模式**，然后去读对应的 MODE 文件。

---

## 🎯 我在干什么

我是一个电子取证比赛的协作 AI（Cascade）。人机分工：
- **用户**：给检材路径、决定方向、处理 GUI 工具（火眼）
- **我**：读题、跑 CLI、写脚本、推理、写答案

---

## 📚 项目目录速览

```
E:\项目\自动化取证\
├─ SESSION_START.md              ← 你正在看的（模式索引）
├─ modes\
│  ├─ MODE_SOLO.md               ← 🅐 单人快速模式：一人一机，少问多跑
│  └─ MODE_COOP.md               ← 🅑 人机协作模式：一人一机，triage 后优先独立题
├─ THREE_MACHINE_SOP.md          ← 🅒 三机 Git 协作模式
├─ roles\ROLE_{phone,pc,server}.md   三机协作时每机的身份卡
├─ shared\cases\_template\       三机协作时的共享仓模板
├─ PLAYBOOK.md                   ← 不同检材类型的套路（所有模式都用）
├─ WP_FORMAT.md                  ← 每 5 题答案的规范格式（所有模式都用）
├─ KARPATHY_GUIDELINES.md        ← 行为准则（引用自 E:\项目\andrej-karpathy-skills-main）
├─ TRANSFER_GUIDE.md             ← 迁移到新 Win11 的 SOP
├─ TOOLS.md                      ← 工具清单
├─ FIC_BATTLE_READY.md           ← 实战前 checklist
├─ scripts\                      ← 部署 + 健康检查脚本
├─ tools\EZ\                     ← Zimmerman 套件（Windows 端）
├─ knowledge\                    ← L1 方法论 + L2 题型分类
└─ cases\<比赛名>\                ← 每个比赛一个
   ├─ questions.md
   ├─ answers.md                 ← 证据链（详）
   ├─ answers_summary.md         ← 提交用摘要
   ├─ handover.md                ← 多 session 交接（最关键）
   ├─ wp_batches\                ← 每 5 题一批
   ├─ evidence -> <检材盘>        ← 只读
   └─ artifacts\                  ← 中间文件
```

---

## 🚦 选模式（按用户情景选一个）

| 情景 | 选哪个 | 特点 |
|------|--------|------|
| 一人一机、题目熟悉、要**最快拿分** | 🅐 **SOLO** | AI 少问、多跑、按 PLAYBOOK 直接上手 |
| 一人一机、题目复杂或陌生，要**高质全局** | 🅑 **COOP** | AI 先做 triage、与用户问答补齐已知信息、优先独立题 |
| 三人三机组队、**有互联网**、Git 可达 | 🅒 **TEAM** | 按板块（phone/pc/server）分工，共享仓 + fact/inbox |

---

## 🎬 我的开场 3 步（按序执行）

**第 1 步：读最新工作日志**（了解上次做到哪）
```powershell
# 找最近一份 worklog
ls worklog/*.md | sort -Descending | Select-Object -First 1
```
读取最新那份 → 吸收"悬而未决"和"下次建议从这里开始"。

**第 2 步：声明已读内容**
一句话回复："已读 SESSION_START 和 worklog 最新一份（`<文件名>`），上次到 `<一句话概括>`。"

**第 3 步：问模式（若用户未指定）**
```
本场走哪个模式？
  🅐 SOLO  — 一人一机，快拿分（默认）
  🅑 COOP  — 一人一机，先 triage 再攻
  🅒 TEAM  — 三机 Git 协作（本机 phone/pc/server?)
```

用户指定后：立刻读对应 MODE 文件 + 相应 workflow，不再问废话。

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
