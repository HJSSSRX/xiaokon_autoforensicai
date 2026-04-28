---
description: SOLO 快速模式的开场流程 — 少问多跑
---

当用户说 /case-solo <比赛名> <检材路径> 或选模式时选 SOLO：

1. `ls cases/<比赛>/evidence/` 看检材
// turbo
2. 读 `cases/<比赛>/questions.md`（若不存在但有 xlsx，用 openpyxl 转）
3. 读 `cases/<比赛>/handover.md`（若存在）
4. 按 `@/modes/MODE_SOLO.md` 的战术开工
5. **直接开始做 Q01-Q05**，不做 triage，不等用户详细确认
6. 做到 5 题自动 /wp-report 汇报

关键：SOLO 模式下，AI 应当**假设默认方向**并声明——用户不反对就继续。例：
"默认从 Q01 开始按题号顺序做，遇到跨题依赖再跳。开工。"

仅在以下情况打断用户：
- 需要密码/口令
- 需要火眼 GUI 操作
- 题目真歧义
- 卡 20 分钟无进展
