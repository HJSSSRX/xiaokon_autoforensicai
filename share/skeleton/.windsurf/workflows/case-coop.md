---
description: COOP 协作模式的开场流程 — triage 后分桶推进
---

当用户说 /case-coop <比赛名> <检材路径> 或在选模式时选 COOP：

## 阶段 1 — 自动扫描（不打扰用户）
// turbo
1. 跑 `powershell -File scripts\env_healthcheck.ps1`，若 FAIL > 0 先修
2. 创建 `cases/<比赛>/` 目录结构（artifacts/, wp_batches/）
3. `ls` 检材目录把文件清单记到 `cases/<比赛>/NOTES.md`
4. 若检材里有 xlsx 题目，用 openpyxl 转成 `questions.md`
5. 读 `questions.md` 全文

## 阶段 2 — 向用户 triage 提问（一次问完）

严格按 `@/modes/MODE_COOP.md` §"阶段 2" 的 5 项清单（A 优先级/B 已知/C 密码/D 时限/E 火眼）**一次发完**。
不要分段问。

## 阶段 3 — 分桶

用户回答后：
1. 把用户提供的"已知答案"先写进 `answers.md` 并标 `[用户提供，待验证]`
2. 把用户提供的密码存到 `cases/<比赛>/SECRETS.md`（标记本地、不上传 git）
3. 分三桶写入 `cases/<比赛>/TRIAGE.md`
4. 用户**确认**分桶合理后才开始执行

## 阶段 4 — 执行

1. 按 独立桶 → 依赖桶 → 硬骨头 顺序
2. 每 5 题自动触发 `/wp-report`
3. 每桶完成时把 TRIAGE 状态表复制到对话
4. 卡 40 分钟或命中弃权指标时立即标记并跳

## 完成条件
- 所有独立桶题 100% 有答案（或显式未解原因）
- `wp_batches/` 至少 N/5 个文件（N = 已做题数）
- `answers_summary.md` 有完整提交用答案表
