# shared/ — 三机 Git 协作共享仓

> 此目录是**整个 Git repo 的心脏**。所有三机 AI 都读这里、写这里。

---

## 目录用途

```
shared/cases/<比赛名>/
├─ TASKS.md              队长维护的分工 + 进度总表
├─ questions.md          题目全文（所有机共享）
├─ answers_merged.md     队长合并后的最终答案（每 30 分钟更新）
├─ facts/                事实库（跨板块公开信息）
│  ├─ phone.md            phone 机写 & 所有机读
│  ├─ pc.md
│  └─ server.md
├─ inbox/                消息队列（跨板块问答）
│  ├─ phone.md            别板块问 phone 的问题，phone 板块答
│  ├─ pc.md
│  └─ server.md
└─ wp_batches/           WP 批次（每板块前缀防冲突）
   ├─ phone-Q01-Q05.md
   ├─ pc-Q21-Q25.md
   └─ server-Q41-Q45.md
```

## 写入规则（死守）

| 文件 | 谁可以写 | 谁可以读 |
|------|---------|---------|
| TASKS.md | **队长** | 所有人 |
| answers_merged.md | **队长** | 所有人 |
| facts/phone.md | **phone 机** | 所有人 |
| facts/pc.md | **pc 机** | 所有人 |
| facts/server.md | **server 机** | 所有人 |
| inbox/phone.md | 所有人**追加**，phone 机**标答** | 所有人 |
| inbox/pc.md | 所有人追加，pc 机标答 | 所有人 |
| inbox/server.md | 所有人追加，server 机标答 | 所有人 |
| wp_batches/phone-* | phone 机 | 所有人 |
| wp_batches/pc-* | pc 机 | 所有人 |
| wp_batches/server-* | server 机 | 所有人 |
| questions.md | 队长**初始化后**冻结 | 所有人 |

---

## 新比赛开始时（队长做）

```powershell
cp -r shared/cases/_template  shared/cases/2026FIC
# 然后：
# - 编辑 shared/cases/2026FIC/TASKS.md 填分工
# - 把题目转成 shared/cases/2026FIC/questions.md
# - git add shared/cases/2026FIC
# - git commit -m "init 2026FIC"
# - git push
```

三机 pull 后即可开工。

---

## 查询顺序（每机 AI 开场 + 每 15 分钟）

```
1. git pull
2. 读 facts/*.md 三个 → 吸收队友事实
3. 读 inbox/<本机板块>.md → 看有没有问我的
4. 看 TASKS.md → 确认分工无变化
5. 做自己的题
```
