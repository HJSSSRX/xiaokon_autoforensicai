# AutoForensicAI v2 — 交接文档

> 最后更新: 2026-05-05 21:34

---

## 一、项目是什么

AI 驱动的电子取证/安全自动化系统。用户说 **"小空自己动"**，AI 进入 Main 设计者模式，根据场景（比赛/训练/灌知识/教育/顾问）自动规划工作、生成角色提示词、协调多窗口协作。

**核心设计决策**：
- **CLI 为主**，不依赖 MCP（35 倍 token 节省，弱模型友好）
- **文件系统协作**，不依赖数据库/消息队列（YAML 文件交换线索）
- **平台无关**：同一套 prompt 适用 Windsurf/Cursor/Claude Code/任何终端 AI
- **知识库闭环**：每次做题/灌入都产生可搜索复用的方案

---

## 二、项目结构

```
e:\项目\自动化取证\
├── CLAUDE.md                          ← Claude Code 触发入口
├── .cursorrules                       ← Cursor 触发入口
├── .windsurf/
│   ├── rules/autoforensicai.md        ← Windsurf 规则触发
│   └── workflows/xiaokong.md          ← Windsurf workflow 触发
├── prompts/
│   ├── main.md                        ← ★ 核心：Main 设计者 prompt（5 种模式）
│   ├── roles/                         ← 5 个专业角色 prompt 模板
│   │   ├── computer_analyst.md        ← 磁盘/内存/注册表/日志取证
│   │   ├── mobile_analyst.md          ← Android/iOS/微信取证
│   │   ├── network_analyst.md         ← 流量分析/tshark
│   │   ├── web_pentester.md           ← Web 渗透/SQLi/XSS/SSRF
│   │   └── stego_crypto_analyst.md    ← 隐写/编码/密码学
│   └── protocols/
│       ├── collaboration.md           ← 多角色协作规范（shared/ YAML 格式）
│       ├── training_auto.md           ← 全自动训练流程
│       └── knowledge_ingest.md        ← 知识灌入流程
├── knowledge/
│   ├── solved/                        ← 已验证解题方案（YAML frontmatter + Markdown）
│   │   ├── example_memory_forensics_pslist.md
│   │   └── test_stego_png_hidden_message.md
│   ├── skills/                        ← 各角色 CLI 速查表
│   │   ├── computer/quick_reference.md
│   │   ├── mobile/quick_reference.md
│   │   ├── network/quick_reference.md
│   │   ├── web/quick_reference.md
│   │   └── stego_crypto/quick_reference.md
│   └── cards/                         ← 外部知识卡（暂空）
├── tools/
│   └── kb_search.py                   ← ★ 知识库搜索工具（已验证可用）
├── bootstrap.ps1                      ← 工具安装检查脚本（已验证可用）
├── tests/                             ← 端到端测试（已全部通过）
│   ├── test_challenge/                ← 模拟隐写题（PNG + flag）
│   ├── test_parse_yaml.py
│   └── test_prompt_gen.py
├── references/                        ← 8 个 GitHub 参考仓库源码
├── DESIGN.md                          ← 总体架构设计（早期版本，部分过时）
├── RESEARCH.md                        ← 8 个参考仓库深度分析
├── DISCUSSION.md                      ← CLI vs MCP 讨论 + 方案反思
├── TOOLCHAIN.md                       ← 工具链清单（MCP 部分已降级为可选）
└── TRAINING.md                        ← 训练方案（早期版本，已被 protocols/ 取代）
```

---

## 三、5 种模式

| 模式 | 触发 | Main 做什么 |
|---|---|---|
| **比赛** | "比赛模式" | 扫描检材→分工→生成角色 prompt→用户开多窗口→shared/ 协作 |
| **训练(全自动)** | "训练模式，全自动" | 已知答案→走完整流水线→验证→写入 KB |
| **训练(半自动)** | "训练模式" | 用户选题→AI 解→用户审 WriteUp |
| **灌知识** | "灌知识模式" | 单窗口提取 URL/文档→结构化→写入 KB |
| **教育** | "教育模式" | 出题→讲解→验证 |
| **顾问** | "顾问模式" 或直接提问 | 搜 KB→返回最相关方案+命令+要点 |

---

## 四、知识库搜索工具用法

```bash
# 按标签搜
python tools/kb_search.py --tags memory_forensics volatility

# 按工具搜
python tools/kb_search.py --tools vol3 strings

# 全文搜
python tools/kb_search.py --text "process injection"

# 按类别搜
python tools/kb_search.py --category stego

# ★ 顾问模式：自然语言（中英文均可）
python tools/kb_search.py --ask "内存取证怎么查可疑进程"
python tools/kb_search.py --ask "PNG图片里藏了东西怎么提取"

# 列出全部
python tools/kb_search.py --all
```

`--ask` 模式会自动：中文分词 → 别名扩展（中→英）→ 三维度搜索（tags/tools/text）→ 计分排序 → 展示 Top 匹配的完整 Solution Steps。

---

## 五、solved 文件格式

```markdown
---
tags: [memory_forensics, volatility, windows]
tools: [vol3, strings]
category: memory_forensics
difficulty: medium
source: ctfshow_forensics_03
date: 2026-05-05
verified: true
---
# Title

## Problem
{题目描述}

## Solution Steps
{带具体 CLI 命令和预期输出的步骤}

## Key Takeaways
{可迁移的知识点}

## Answer
flag{...}
```

---

## 六、已验证通过的测试

端到端测试于 2026-05-05 全部通过：

1. ✅ 触发机制（main.md 可读取，5 模式定义清晰）
2. ✅ KB 搜索空库（正确返回无结果）
3. ✅ Skill 文件引导（搜 PNG 命中 stego_crypto 速查表）
4. ✅ CLI 解题（strings → base64 -d → 得到 flag）
5. ✅ 写入 KB（生成标准 solved 文件）
6. ✅ KB 搜索有数据（tags/text/tools 三种搜索全部命中）
7. ✅ 协作 YAML 解析（findings.yaml 可被 yaml.safe_load 正常读取）
8. ✅ 角色 prompt 生成（5 个模板全在位）
9. ✅ 顾问模式中文搜索（"内存取证查进程" → 命中 memory forensics solved）
10. ✅ 顾问模式跨语言（"微信聊天记录" → 展开为 wechat/tencent → 命中 mobile skill）

---

## 七、已知局限 & 下一步

### 已知局限
- `TERM_ALIASES` 需要手动维护，覆盖面有限
- 搜索无索引，文件多（1000+）时会变慢 → 可加 SQLite FTS5
- `DESIGN.md` / `TRAINING.md` / `TOOLCHAIN.md` 是早期文档，部分内容与当前实现不一致
- knowledge/cards/ 暂空，灌知识流程未实际跑过
- 教育模式只有定义，未实现

### 建议下一步
1. **用真实 CTF 题目跑一遍全自动训练**，验证完整流水线
2. **灌入 references/ 里已有的 ctf-skills 知识**到 knowledge/skills/（350KB 高质量取证技能）
3. **清理早期文档**：DESIGN.md/TRAINING.md/TOOLCHAIN.md 与当前实现对齐或标记过时
4. **扩充 TERM_ALIASES**：随着实际使用，补充更多中英文术语映射
5. **考虑 git 管理**：骨架仓库已有 https://github.com/HJSSSRX/xiaokon_autoforensicai.git

---

## 八、用户偏好（必须遵守）

- 始终用**简体中文**对话，代码注释保持英文
- **CLI 优先**，MCP 仅用于无 CLI 的工具（Burp Suite/Autopsy）
- 不要照搬参考项目，要独立思考
- 参考项目只是启发，取其精华
- 全自动训练，实战半自动步步为营
- 简单优先，不做推测性设计
