# 自动化取证

面向国内电子取证比赛（平航杯 / 盘古石杯 / FIC / 美亚杯）的半自动化解题项目。

---

## 🚀 快速入门

### 三种工作模式（按情景选）

| 模式 | 场景 | 入口文件 |
|------|------|---------|
| 🅐 **SOLO** 单人快速 | 一人一机、题型熟、要最快拿分 | `modes\MODE_SOLO.md` |
| 🅑 **COOP** 人机协作 | 一人一机、题目复杂、要高质全局 | `modes\MODE_COOP.md` |
| 🅒 **TEAM** 三机 Git 协作 | 三人三机、互联网可达 | `THREE_MACHINE_SOP.md` |

### 按场景找文档

| 我是谁 | 先读哪份 |
|--------|---------|
| 下一次会话的 **Cascade** | `SESSION_START.md` (选模式入口) |
| 新机器部署者 | `TRANSFER_GUIDE.md` + 跑 `scripts\bootstrap_new_machine.ps1` |
| TEAM 模式新成员 | 跑 `scripts\team_init.ps1 -RepoUrl <gitee 地址> -Role <phone\|pc\|server>` |
| 赛前 1 小时 | `FIC_BATTLE_READY.md` |
| 看 AI 行为准则 | `KARPATHY_GUIDELINES.md` |
| 按检材找套路 | `PLAYBOOK.md` |
| WP 规范 | `WP_FORMAT.md` |

### Windsurf 斜杠命令（`.windsurf\workflows\`）

- `/case-solo <比赛> <检材路径>` — SOLO 模式开局
- `/case-coop <比赛> <检材路径>` — COOP 模式开局（含 triage）
- `/wp-report <起> <止>` — 每 5 题批次报告
- `/team-sync` — TEAM 模式 Git 同步一次循环
- `/env-check` — 环境健康检查

---

## 设计前提

- **环境**：Windows 11 + WSL2 (Ubuntu)，Windows 端 `E:\` 在 WSL 内以 `/mnt/e` 访问。
- **商业工具**：火眼证据分析、火眼移动取证、火眼仿真（均为 GUI，不参与自动化，作为"人肉后备"）。
- **自动化主力**：开源 CLI 工具集（见 `TOOLS.md`）。
- **解题模式**：工具箱 + Cascade 在会话内人肉驱动。用户给 Excel + 检材路径，Cascade 逐题调用脚本、读输出、推理、回答。

## 流程概览

1. 新案子：在 `cases/<案子名>/` 下放 `questions.xlsx` 与原始检材。
2. 用户在 Windsurf 会话里告诉 Cascade 案子路径。
3. Cascade 按 `PLAYBOOK.md` 的检查单逐类检材做**识别 → 提取 → 索引**，产物落到 `cases/<案子名>/artifacts/`。
4. Cascade 打开 Excel，逐题分析，必要时写新脚本到 `scripts/`（要求幂等、输出 JSON 或规整文本）。
5. 无法靠开源工具解决的题（例如需要看到已登录桌面状态的截图），由用户在火眼对应模块里手动操作，把导出目录告诉 Cascade。

## 目录结构

```
自动化取证/
├── README.md          # 本文件
├── PLAYBOOK.md        # 拿到新案子的操作检查单（Cascade 必读）
├── TOOLS.md           # 工具清单与安装命令
├── knowledge/         # 通用取证知识库（可给其他 AI 助手用）
│   ├── README.md            # 知识库使用说明
│   ├── tools_cheatsheet.md  # 工具速查表
│   ├── playbook/            # 按检材类型分的解题套路
│   │   ├── android.md
│   │   ├── windows.md
│   │   ├── linux_server.md
│   │   ├── memory.md
│   │   ├── network_pcap.md
│   │   ├── dotnet_reverse.md
│   │   ├── javascript_malware.md
│   │   └── domain_ad.md
│   └── competitions/        # 各比赛题型分类（不含具体答案）
│       ├── 平航杯.md
│       ├── 盘古石杯.md
│       ├── 美亚杯.md
│       └── FIC.md
├── tools/             # 便携版 Windows 工具（Zimmerman 套件等）
├── scripts/           # 按需添加的解析脚本（Python）
└── cases/             # 每个案子一个子目录（.gitignore）
    └── <案子名>/
        ├── questions.xlsx
        ├── evidence/        # 原始检材（只读）
        └── artifacts/       # 脚本输出（时间线、导出的 SQLite、JSON 报告等）
```

## 知识库用法

`knowledge/` 是项目核心资产，设计成**独立可用**：
- 可以原样复制给其他 AI 助手（GPT / DeepSeek / Qwen 等）使用
- 不依赖本项目的特定路径，所有示例命令用 `$EVIDENCE`、`$OUT` 占位
- 分 L1（通用方法论）+ L2（题型分类），**不含 L3 具体答案**
- 新经验请回填到对应 `playbook/*.md` 或 `competitions/*.md`

## 首次使用

按 `TOOLS.md` 的清单装工具。装完后告诉我第一个案子的路径即可。
