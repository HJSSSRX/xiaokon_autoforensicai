# ForHacker 跨机器协作指南

> 本文档适用于所有协作者（人类和 AI），介绍如何在多台电脑之间协同工作。

---

## 概述

ForHacker 支持三种协作模式：

| 模式 | 适用场景 | 前提条件 |
|---|---|---|
| **A. 单机多窗口** | 一台电脑多个 AI 窗口 | 无 |
| **B. Git 同步** | 有互联网，多台电脑 | GitHub 账号 |
| **C. LAN 同步** | 断网/比赛局域网 | 能互相 ping 通 |

---

## 快速开始

### 第 0 步：每台机器安装项目

```powershell
git clone https://github.com/HJSSSRX/xiaokon_autoforensicai.git forhacker
cd forhacker
.\install.ps1              # 一键安装所有工具
python tools\tool_status.py --missing   # 确认没有遗漏
```

### 第 1 步：创建案件工作区（队长/总设计师执行一次）

```powershell
# 创建案件目录
mkdir E:\case_2025phb
mkdir E:\case_2025phb\shared

# 初始化 Git（如果用 Git 模式）
python tools\collab_sync.py git-init E:\case_2025phb --repo https://github.com/team/case_2025phb.git
git push -u origin main
```

### 第 2 步：其他队员加入

```powershell
# 克隆案件仓库
git clone https://github.com/team/case_2025phb.git E:\case_2025phb

# 或 LAN 模式：直接创建本地目录
mkdir E:\case_2025phb\shared
```

### 第 3 步：开始工作

每个队员在自己的电脑上打开 AI 窗口，粘贴对应的角色 prompt（由总设计师生成并分发），开始分析。

---

## 模式 A：单机多窗口

最简单的模式。所有 AI 窗口读写同一个 `shared/` 目录，不需要任何同步。

```
你的电脑
├── 窗口1: 总设计师（小空）  → 读 shared/ 监控进度
├── 窗口2: 手机取证师        → 写 shared/findings.yaml
├── 窗口3: 流量分析师        → 写 shared/findings.yaml
└── 窗口4: 计算机取证师      → 写 shared/findings.yaml
```

---

## 模式 B：Git 同步（有互联网）

每台机器的 AI 定期 pull/push `shared/` 目录。

```
机器A（小明）              GitHub 仓库               机器B（小红）
  总设计师               case_2025phb/               手机取证师
  流量分析师        ←── shared/findings.yaml ──→     计算机取证师
                        shared/answers.yaml
                        shared/progress.yaml
```

**AI 角色的操作**（写在角色 prompt 中）：
```powershell
# 每次写入 findings 之后
python tools\collab_sync.py git-push E:\case_2025phb -m "mobile: found trojan MD5"

# 每次开始新一轮分析之前
python tools\collab_sync.py git-pull E:\case_2025phb
```

**总设计师的操作**：
```powershell
# 定期拉取最新进度
python tools\collab_sync.py git-pull E:\case_2025phb

# 查看全局状态
python tools\collab_sync.py status E:\case_2025phb

# 查看答案表
python tools\collab_sync.py answers E:\case_2025phb
```

---

## 模式 C：LAN 同步（断网/比赛局域网）

一台机器（通常是总设计师的）运行 HTTP 同步服务器，其他机器通过 HTTP 推送/拉取。

### 服务端（总设计师的电脑）

```powershell
python tools\collab_sync.py lan-serve E:\case_2025phb --port 9999
```

启动后会显示本机 IP，类似：
```
╔══════════════════════════════════════════╗
║   LAN Sync Server — port 9999            ║
╚══════════════════════════════════════════╝
  Other machines connect with:
    python collab_sync.py lan-pull <case_dir> --server 192.168.1.100:9999
```

### 客户端（其他队员的电脑）

```powershell
# 拉取最新数据
python tools\collab_sync.py lan-pull E:\case_2025phb --server 192.168.1.100:9999

# 推送自己的发现
python tools\collab_sync.py lan-push E:\case_2025phb --server 192.168.1.100:9999
```

---

## 发布发现（所有模式通用）

任何 AI 角色发现重要线索时：

```powershell
python tools\collab_sync.py post E:\case_2025phb ^
    --from mobile_analyst ^
    --summary "木马 APK MD5 = ABC123" ^
    --detail "包名 com.example.reverseshell2, C2 = 1.2.3.4:4444" ^
    --related "server_analyst,computer_analyst"
```

也可以直接编辑 `shared/findings.yaml`（追加即可）。

---

## shared/ 目录文件说明

| 文件 | 谁写 | 格式 |
|---|---|---|
| `findings.yaml` | 所有角色追加 | `- id: F001, from: xxx, summary: xxx` |
| `answers.yaml` | 总设计师维护 | `- num: 1, category: 手机, answer: xxx, status: ✅` |
| `progress.yaml` | 各角色更新自己 | `- role: xxx, status: working, done: 5, total: 13` |
| `questions.yaml` | 跨角色 Q&A | `- from: xxx, to: xxx, question: xxx` |
| `timeline.yaml` | 所有角色追加 | `- time: xxx, event: xxx, source: xxx` |

**规则**：
1. **只追加，不修改他人记录**
2. 每条记录有唯一 `id`（F001, F002...）
3. 有跨角色关联时标记 `related_to`
4. 总设计师负责从 findings 提取答案到 answers

---

## 分工建议

三人队伍典型分工：

| 队员 | 电脑 | AI 角色 | 负责检材 |
|---|---|---|---|
| 队长 | 电脑 A | **总设计师** + 流量分析师 | BLE/USB 流量 |
| 队员 B | 电脑 B | 手机取证师 + 计算机取证师 | 手机备份 + PC 镜像 |
| 队员 C | 电脑 C | 服务器取证师 + 逆向工程师 | VMDK + EXE |

每个角色的 prompt 由总设计师生成（含检材路径、题目、工具位置），队员只需把 prompt 粘贴给 AI 窗口即可开始。

---

## 常见问题

**Q: Git push 冲突怎么办？**
A: findings.yaml 是 append-only 设计，大部分情况 git 自动合并。如遇冲突，手动保留所有条目即可。

**Q: 检材太大怎么同步？**
A: 检材不入 git。每台电脑自行复制检材到本地。shared/ 只同步 YAML 文件（KB 级别）。

**Q: 断网怎么办？**
A: 用 LAN 模式。只需一根网线（或 WiFi 热点）连接几台电脑，在队长机器上 `lan-serve`。

**Q: 可以混用模式吗？**
A: 可以。本地窗口直接读写 shared/，远程机器用 Git 或 LAN 同步。不冲突。
