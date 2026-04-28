# TASKS — <比赛名> 团队分工

> 队长初始化后**只由队长**维护。其他机只读。

**比赛**：
**开始时间**：
**预计时长**：
**答题提交地址**：

---

## 检材清单

| 路径（Git 仓里的相对路径 / 各机本地挂载） | 类型 | 归属板块 |
|------------------------------------------|------|---------|
| `evidence/phone/zhang.tar` | Android tar | phone |
| `evidence/pc/li.E01` | Win E01 | pc |
| `evidence/pc/mem.vmem` | 内存 dump | pc |
| `evidence/server/server.E01` | Linux E01 | server |
| `evidence/server/traffic.pcapng` | pcap | server |

---

## 题目分工

| 题段 | 板块 | 负责机 | 题数 | 预估用时 |
|------|------|-------|------|---------|
| Q01-Q17 | phone | 机 1 | 17 | 2.5h |
| Q18-Q37 | pc | 机 2 | 20 | 3h |
| Q38-Q48 | pc | 机 2 | 11 | 1.5h |
| Q49-Q60 | server | 机 3 | 12 | 2h |
| Q61-Q66 | server | 机 3 | 6 | 1h |
| Q67-Q71 | pc | 机 2 | 5 | 1h |

---

## 跨板块依赖预告

| 依赖题 | 需要的信息 | 提供板块 |
|--------|----------|---------|
| Q38 (pc) | 手机 IMEI + UIN | phone |
| Q52 (pc) | Linux root 密码 | server |
| Q65 (server) | PC 注册表某键 | pc |

---

## 进度（每 30 分钟更新）

### T+00:00
- [x] Git 仓初始化
- [x] TASKS.md 发布
- [ ] 三机 clone + checkout 分支
- [ ] 三机 env_healthcheck 通过

### T+00:30
（填）

### T+01:00
（填）

...
