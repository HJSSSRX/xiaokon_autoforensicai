---
description: TEAM 模式下 Git 同步一次循环（commit → pull → 读 facts/inbox → push）
---

当用户说 /team-sync 或每 5 题 /wp-report 后自动触发：

## 1. 提交本机工作

```bash
cd <团队仓根>
git status
git add shared/cases/<比赛>/facts/<本板块>.md       # 新增 facts
git add shared/cases/<比赛>/inbox/<本板块>.md       # 答复的 inbox
git add shared/cases/<比赛>/wp_batches/<本板块>-*.md
git commit -m "<本板块> T+HH:MM: +N题 / +M facts / answered K inbox"
```
// turbo

## 2. 拉取队友更新

```bash
git pull --rebase origin main
```

若出现 rebase 冲突：**立刻停**，向用户报告冲突文件和冲突行。
冲突可能在 `TASKS.md` 或 `answers_merged.md`（这两个是队长写的，本机不该动）。

## 3. 读队友新事实 + 新问题

读（diff 看"自上次同步有啥变化"优先，没 diff 工具就全读）：
- `shared/cases/<比赛>/facts/*.md` （三个）
- `shared/cases/<比赛>/inbox/<本板块>.md`

## 4. 处理新发现

- 新 facts 里**能帮当前题**的立刻用
- inbox 里**能马上答**的立刻答（追加到 facts + 标 [✅]），**不能马上答**的继续做自己的
- 若新 facts **解锁**了之前卡住的依赖题 → 立刻拉回做

## 5. 推送工作分支

```bash
git push origin <本板块>-work
```
// turbo

## 6. 报告给用户

```
🔄 /team-sync 完成 T+HH:MM
- 本机提交：N题 / M facts / answered K inbox
- 拉取到：phone 新 X facts / pc 新 Y facts / server 新 Z facts
- 新解锁：Q<依赖题> 现在可以做了（facts F-XX-NNN 提供 <线索>）
- 待答 inbox：K 条（简短列出主题）
下一步：继续 Q<NN>。
```
