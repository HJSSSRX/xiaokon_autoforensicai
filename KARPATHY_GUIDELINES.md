# KARPATHY_GUIDELINES — Cascade 行为准则（引用）

> 本文档的**完整正文**位于 `E:\项目\andrej-karpathy-skills-main\CLAUDE.md`，
> 由 Andrej Karpathy 关于 LLM 常见编码误区的观察提炼而来。
>
> 本文件在自动化取证项目里的作用：**把那四条准则固化为我（Cascade）在取证解题时的默认行为**。
>
> ⚠ 若迁移到新机器且全局规则未同步，请**手动**把 `andrej-karpathy-skills-main\CLAUDE.md` 内容粘到 Windsurf Global Rules。

---

## 外部资产位置

```
E:\项目\andrej-karpathy-skills-main\
├─ README.md       准则的背景与使用说明（可读性好）
├─ CLAUDE.md       准则正文（65 行，用户应粘到 Windsurf 全局规则）
└─ EXAMPLES.md     好/坏示例对比（选读）
```

来源：<https://github.com/forrestchang/andrej-karpathy-skills>

---

## 四条准则（取证场景下的翻译）

### 1. Think Before Coding — 先想再跑

取证场景翻译：
- **先读题再动手**。题目问 "登录次数" 时，要先想"登录定义是什么？wtmp 还是 evtx 4624？"，不要抓起 `last` 就跑。
- 题目模糊时**列出候选解读**，让用户选。
- 有更简单的路径（如火眼 GUI 能 3 秒出结果）时，说出来。

### 2. Simplicity First — 简单优先

- 一次性脚本就写 `artifacts/<题号>_*.sh`，不要放 `scripts/` 变成"通用工具"。
- 不做没要求的"批量题解框架"。每个比赛自己的 PLAYBOOK 就够。
- 如果 200 行脚本能换成 `sqlite3 xxx.db "SELECT ..."`，就换。

### 3. Surgical Changes — 外科改动

- 用户让我"补 Q03"就只补 Q03，不要顺手修 Q02 格式。
- `answers.md` 里别人写的格式保留，哪怕我不喜欢。
- 发现 `artifacts/` 里别的脚本有 bug，**提一句**让用户决定，不擅自修。

### 4. Goal-Driven Execution — 目标驱动

- 每题的"成功标准"是：**答案 + 证据路径 + 可复现命令** 三件齐。
- 不达三件齐，不算做完。
- 不能"我觉得应该是 xxx"，必须能指向 `artifacts/Q10_out.txt` 的哪一行。

---

## 语言与风格（全局规则第 0 条 · 始终遵守）

- 与用户**始终用简体中文**对话
- 代码注释保持英文（除非用户明确要求中文）
- 响应简洁，不做 "You're absolutely right!" 类吹捧
- Markdown 格式，关键词加粗
- 文件路径用反引号或 `@/绝对路径:行号` 格式引用

---

## 在本项目里怎么体现

- `SESSION_START.md` 第 6 节的"死规矩"就是这四条准则的落地
- `WP_FORMAT.md` 里"不作弊声明"对应准则 4（目标驱动的"可复现"要求）
- `PLAYBOOK.md` 第 0 节"开场，不要跳"对应准则 1（先想再跑）
- 每次 AI 回复应当能回答："我这次编辑改了哪几行？每一行对应用户的哪个请求？"（准则 3）

---

## FIC2026 赛后教训（2026-04-26 补）

以下是本次实战对 Karpathy 四准则的**具体违反案例**和修正建议：

### 违反准则 1（先想再跑）
- **案例**: C03/C08 邮件题上来就 grep 关键词，没有先建全量索引
- **修正**: 邮件类题，先用 Python email 模块建 CSV 索引（发件人/主题/日期/附件），再搜

### 违反准则 2（简单优先）
- **案例**: 试图用 openssl 命令行组合暴力尝试 AES 解密，而不是先理解反汇编中的 XOR mask
- **修正**: 逆向题先完整读懂比较函数，画出数据流，再写最小 Python 脚本验证

### 违反准则 3（外科改动）
- **案例**: PowerShell+WSL 内联 bash 反复调试，每次"稍微改一下"引入新 bug
- **修正**: 复杂命令**直接写文件**，不要内联修修补补

### 违反准则 4（目标驱动）
- **案例**: M10 DJI 飞行日志花了 25 分钟尝试各种解密方案，没有先证伪"V12+ 能否离线解密"
- **修正**: 搜索 10 分钟无结果时，先问"我假设的目标存在吗？能否证伪？"
