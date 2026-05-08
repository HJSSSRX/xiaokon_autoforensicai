# 2026FIC 初赛 — 计算机取证复盘 + 检材筛选 DSL

> **状态：等待总设计师批阅**
> **作者：computer_analyst（小空协作子角色）**
> **提交时间：2026-05-08**

---

## 背景

2026FIC 初赛已结束并放出官方 wp（<https://mei-you-qian.github.io/2026/05/07/2026FIC%E5%88%9D%E8%B5%9B/>）。
对照后发现本次 **计算机取证 10 题中，仅 4 题正确**（Q1/Q2/Q3/Q5），1 题语义错（Q6），5 题完全错（Q4/Q7/Q8/Q9/Q10）。

本次提交两份文档以请示总设计师：

| 文件 | 用途 | 建议归属 |
|---|---|---|
| [`POSTMORTEM_computer_v1.md`](./POSTMORTEM_computer_v1.md) | 案件特化的逐题复盘 + 错因 + 优化方案 | 留在 `cases/2026FIC/` |
| [`TRIAGE_DSL_v1.md`](./TRIAGE_DSL_v1.md) | **通用**检材筛选 DSL（让低性能 AI 用极少 token 完成 triage） | 建议提级到 `knowledge/skills/` |
| [`answers_final_legacy.md`](./answers_final_legacy.md) | 旧答案表（保留作反面教材，不删） | 留在本目录 |

---

## 关键结论（TL;DR）

### 1. 错因排序（按破坏力）

| # | 根因 | 涉及题号 |
|---|---|---|
| 1 | **vc 容器类型误判**（标准 VeraCrypt → 误读为自定义 RC4-VHD） | Q8/Q9/Q10 |
| 2 | **保险柜 ≠ vc 容器**（语义绑定污染） | Q9/Q10 |
| 3 | **未做 RSA Fermat 弱密钥扫描**（p,q 接近，CTF 入门） | Q4 |
| 4 | **不知 UOS AI 是 deepin 自带桌面 AI**（搜索域不全） | Q6/Q7 |
| 5 | **滥用跨角色协作**（找不到就转手，不深挖自己检材） | Q7/Q8/Q9/Q10 |
| 6 | **mp4-stco / WPS-OLE / Go-ELF 不熟**（推给 binary） | Q8/Q9/Q10 |

**一句话**：用了 binary 角色的反汇编思维做了 computer 角色的痕迹取证题。

### 2. TRIAGE-DSL v1 核心特性

- 单行 8 字段：`PRIO|PATH|SIZE|SIG|KEYS|QMAP|ACT|NOTE`
- 5 级优先级（默认 SKIP，正向证据才升级）
- 10 个动作动词（OPEN/GREP/XREF/KDF/STEGO/MOUNT/DECRYPT-WITH/EMU/DECOMP/ASK）
- **token 压缩比 ~600x**（8 万行文件树 → 200 行 DSL ≈ 6k tokens）
- 完整 system prompt 模板可直接喂给低性能 AI
- 在本案上验证：13 个 P0 路径覆盖 10 题答案点

---

## 请总设计师评估的问题

1. **DSL 是否提级到 `knowledge/skills/TRIAGE_DSL_v1.md`？**（属于通用做题工具，不限于本案）
2. **POSTMORTEM 提到的"做题流程 T0-T5"是否要写入 `COLLABORATION_GUIDE.md` / `TEAM_GUIDE.md`？**
3. **是否在 `prompts/` 下加一个 `triage_low_model.prompt.md`，封装 §7 的 system prompt？**
4. **是否需要写一个 `tools/triage_walker.py` 脚本**，给定挂载点 + 题目集，自动跑 DSL 输出？

---

## 不做的事（边界约束）

- 不擅自修改 `COLLABORATION_GUIDE.md` 等顶层文档
- 不擅自把 DSL 升入 `knowledge/skills/`
- 不擅自起 hub 服务 / 改协作协议
- 不再向 hub 推 finding（hub 不可达，且本次复盘是事后总结，无新证据）

请批阅后给指示。
