# 2026 FIC 团体赛 — 知识库归档

> **比赛模式**: real_competition（真题/线上赛）
> **题目总数**: 52 题（手机17 + 服务器17 + 互联网3 + 二进制5 + 计算机10）
> **角色配置**: 4 个分析师 + 1 个主设计师（小空）
> **协作模式**: HTTP Hub v3（端口 8765 + cloudflared 公网隧道）
> **检材原始路径**: `E:\ffffff-JIANCAI\2026FIC团体赛\` （不在版本控制内，单机本地）

---

## 文件导航

| 文件 | 用途 | 给谁看 |
|---|---|---|
| `README.md`（本文件） | 比赛入口、上下文介绍 | 人类 + AI |
| `MASTER_SHEET.md` | **实时主表**：52 题进度一览 | 人类（看进度） |
| `mobile.md` | 手机取证 17 题详细解析 | 人类（学习） |
| `server.md` | 服务器取证 17 题详细解析 | 人类 |
| `internet.md` | 互联网取证 3 题详细解析 | 人类 |
| `binary.md` | 二进制取证 5 题详细解析 | 人类 |
| `computer.md` | 计算机取证 10 题详细解析 | 人类 |
| `evidence_index.md` | 检材文件路径索引 + 关键 offset/inode | 人类 + AI |
| `findings_snapshot.yaml` | 来自 Hub 的 findings.yaml 快照（自动同步） | AI（机读） |
| `MASTER_SHEET.xlsx` | Excel 版答案表（总览 + 5 类别 sheet + 跨角色发现） | 人类 |

> **更新机制**：每当主设计师（我，小空）通过 Hub 把新答案写入 `case/shared/answers.yaml`，运行 `tools/sync_kb.py` 即可自动更新此目录所有 md / xlsx / yaml 文件。

---

## 实时 Dashboard（人类看进度用）

**主机浏览器**：http://127.0.0.1:8765/dashboard

**同 WiFi 远程机**：http://&lt;主机LAN IP&gt;:8765/dashboard

**跨网段远程机**：&lt;cloudflared URL&gt;/dashboard

5 秒自动刷新，含：
- 4 角色状态卡片（状态徽章 + 上次更新时间 + 当前任务）
- 52 题矩阵（点击单格看答案预览）
- 实时发现流（点击 finding 弹详情 + 跳转关联）
- 卡点 + 跨角色问题 + 主设计师决策时间轴 + 当前策略

详细使用说明见项目根目录 [`REMOTE_COLLAB_GUIDE.md`](../../../REMOTE_COLLAB_GUIDE.md)。

---

## 案件背景（综合 5 个角色 prompt 提取）

某日，警方接到举报，互联网上出现一涉黄网站极为活跃并大肆推广。警方锁定网站运营者 **李安弘**，在对其实施抓捕的现场对电子数据进行了提取固定。

经审讯，李安弘弓雇佣了**技术人员架设涉黄视频平台**，并找境外团队推广网站，还有多种其他违法行为用以牟利。

涉案角色：
- **李安弘** — 主犯
- **马慧美** — 涉黄视频平台用户
- **网站搭建人员** — 技术服务方
- **云服务器商家** — 提供服务器（uuuim 聊天联系）

涉案数字资产：
- **手机**: Redmi Note 7 Pro（含 uuuim 聊天 APP、AI 助手 PocketPalAI、无人机日志、视频类恶意 APP）
- **服务器**: Debian 13 trixie，跨双盘 LVM（VG volum/LV root 加密 + VG root/LV data btrfs）
- **U盘**: 含 SampleVC.exe 加密程序 + 加密的交易记录文件
- **计算机**: 李安弘日常用机（含邮件、AI、VPN、勒索软件信息）

---

## 解题协作流程（v3）

```
┌──────────────┐                                      ┌──────────────┐
│ mobile_an.   │ ─POST /findings──┐         ┌─POST───→│ server_an.   │
│ (远程机1)    │                  │         │         │ (本机1)      │
└──────────────┘                  ↓         ↑         └──────────────┘
                            ┌─────────────────┐
                            │  Collab Hub v3  │ ←─跨角色 questions/answers
                            │  (port 8765)    │
                            └─────────────────┘
                                  ↑         ↑
┌──────────────┐                  │         │         ┌──────────────┐
│ binary_an.   │ ─POST /findings──┘         └─POST───→│ computer_an. │
│ (本机2)      │                                       │ (远程机1)    │
└──────────────┘                                       └──────────────┘

         ↑ ↑ ↑                                                ↑ ↑ ↑
         GET 拉态势                                           GET 拉态势

                    ┌────────────────────────┐
                    │  小空（主设计师）       │
                    │  - 提炼 findings → 答案  │
                    │  - 维护 MASTER_SHEET    │
                    │  - 路由跨角色信息        │
                    │  - 监控卡点 + 兜底       │
                    └────────────────────────┘
```

---

## 主要里程碑

- **2026-05-07 14:00** — v3 协作系统设计完成（Hub + 4 角色 prompt 改造）
- **2026-05-07 15:00** — Hub + 25 项测试通过
- **2026-05-07 15:18** — 本机 server/binary 首次通过 Hub 提交
- **2026-05-07 15:58** — cloudflared 公网隧道建立，远程机可接入
- **2026-05-07 21:00** — mobile（远程机2）爆发 21 条 finding，完成 17/17 题
- **2026-05-07 21:30** — 主设计师入库 20 个高置信答案，建立本归档目录
- **2026-05-07 21:50** — 实时 Dashboard 上线（8765/dashboard 路由）
- **2026-05-07 21:53** — computer（远程机1）POST 11 条 finding，Q1-Q6 全部出结果，进入跨角色问题阶段

## 当前完成度（快照）

> 实时数据以 [`MASTER_SHEET.md`](MASTER_SHEET.md) / `MASTER_SHEET.xlsx` / Dashboard 为准。

| 类别 | 总数 | 备注 |
|---|---|---|
| 手机取证 | 17 | mobile_analyst (远程机2 / cloudflared) |
| 服务器取证 | 17 | server_analyst (本机) |
| 互联网取证 | 3 | server_analyst (本机) |
| 二进制取证 | 5 | binary_analyst (本机) |
| 计算机取证 | 10 | computer_analyst (远程机1 / LAN) |
| **总计** | **52** | 4 角色 × 1 主设计师 |
