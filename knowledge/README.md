# 电子取证比赛知识库

面向 LLM / AI 编码助手（Claude / GPT / DeepSeek / Qwen 等）的方法论知识库。
专门针对中文电子取证类比赛（平航杯、FIC、盘古石杯、网鼎杯取证方向、行业应急赛）。

---

## 给现场用户的使用说明（FIC 2026 实战）

**最高效路径**：使用 AI 顾问 CLI，让 DeepSeek 接手指导你

```powershell
python E:\项目\自动化取证\scripts\ask_advisor.py "题目原文"
```

详见 [`HOWTO_USE_ADVISOR.md`](./HOWTO_USE_ADVISOR.md)。配置一次 5 分钟，¥10 够跑整场比赛。

---

## 给 AI 助手的使用说明

**你（AI）在接手一场电子取证比赛时，按以下顺序读这份知识库**：

1. **先扫 `wp_index/INDEX.md`** —— 看有哪些精到题的历年记录可参考
2. **读 `tools_cheatsheet.md`** —— 知道手头有什么工具、每个工具干什么
3. **扫一眼 `competitions/` 下对应比赛的题型分类** —— 知道这场比赛的出题套路
4. **根据检材类型，打开对应 `playbook/*.md`**：
   - 安卓压缩包 → `playbook/android.md`
   - Windows 磁盘镜像 → `playbook/windows.md`
   - Linux 服务器镜像 → `playbook/linux_server.md`
   - 内存镜像 → `playbook/memory.md`
   - pcap 流量包 → `playbook/network_pcap.md`
   - .NET 可执行文件 → `playbook/dotnet_reverse.md`
   - JavaScript / WSF / VBS 恶意脚本 → `playbook/javascript_malware.md`
   - AD 域环境分析 → `playbook/domain_ad.md`
4. **开始解题，遇到 playbook 没覆盖的题型时**：在 `playbook/` 下补充新段落，方便下次。

---

## 分层原则（严格遵守）

| 层级 | 内容 | 使用场景 |
|---|---|---|
| **L1 通用方法论** | 工具用法、取证通识、"这类题通常看这个文件"的经验 | 永远可用，不涉及作弊 |
| **L2 历届题型分类** | 某个比赛常考哪些方向、典型难度分布、常见坑 | 永远可用，不含具体答案 |
| **L3 具体 writeup / 答案** | 某届某题的完整解答 | **只在赛后复盘使用**，现赛禁读 |

本知识库 **只包含 L1 + L2**。L3 不在此目录下，建议单独放到 `writeups/`（被 `.gitignore`）。

---

## 核心工作原理（所有 AI 助手都应遵循）

1. **AI 不读二进制**。所有检材必须先经工具转成结构化文本（CSV / JSON / SQLite / 解压后的文件树），AI 只读文本。
2. **AI 不开 GUI**。火眼证据分析、dnSpy、jadx-GUI、Wireshark GUI 这些需要人类操作的工具，由人类跑，AI 读导出。
3. **AI 不猜**。当 playbook 说"用 X 工具"但机器上没装 X，AI 应该立即说"缺 X，请装"，而不是硬上替代方案。
4. **AI 定义成功标准**。每题回答必须包含：答案 + 证据路径（哪个文件的第几行/哪个字段）+ 置信度（高/中/低）。
5. **AI 识破沉没成本**。单题耗时超过预算（例如 15 分钟）就换题，不死磕。

---

## 目录

```
knowledge/
├── README.md                       # 本文件
├── tools_cheatsheet.md             # L1：工具速查表
├── playbook/                       # L1：分类型解题套路
│   ├── android.md
│   ├── windows.md
│   ├── linux_server.md
│   ├── memory.md
│   ├── network_pcap.md
│   ├── dotnet_reverse.md
│   ├── javascript_malware.md
│   └── domain_ad.md
└── competitions/                   # L2：比赛题型分类
    ├── README.md
    ├── 平航杯.md
    └── FIC.md
```

---

## 维护约定

- 每次比赛/练习完，回填 `competitions/<赛事>.md` 里的"考察点"和"坑点"段落（不要写答案）
- 新发现的工具或套路，追加到对应 `playbook/*.md`
- 纯 Markdown，不依赖任何特定项目路径。所有示例命令用 `$EVIDENCE`、`$OUT` 等通用占位符
