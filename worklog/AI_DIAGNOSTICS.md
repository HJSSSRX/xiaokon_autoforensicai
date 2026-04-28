# AI_DIAGNOSTICS — Cascade 自诊断与迭代笔记

> 每次"明显卡住"或"反复踩同一个坑"时，追加到这里。
> 每场比赛/会话开头，**强制读本文件**，把对应的"修复模板"预加载到工作记忆里。

---

## 🧨 卡点模式清单（按痛苦度排序）

### Pattern A：PowerShell → WSL bash 的引号地狱
**症状**：`awk '{print $3}'`、`grep -E '^[0-9]'`、`"$VAR"` 在 `wsl -e bash -c "..."` 里被 PowerShell 解释，出 parser error。

**触发次数**（本会话）：**至少 8 次**，浪费 ≥ 10 分钟

**根因**：PowerShell 会先解析 `$`、`()`、`"`，导致传给 bash 的命令不是我以为的那个。

**永久修复**：
- 🚫 **禁用**：`wsl -e bash -c "<复杂 bash>"`
- ✅ **正确做法**：把 bash 脚本用 `Set-Content -Encoding UTF8` 写到 `artifacts/*.sh`，再 `wsl -e bash /mnt/e/.../xxx.sh`
- ✅ **阈值**：命令行里出现 `$`、`` ` ``、`'`、`"` 的组合 ≥ 2 个 → 直接写文件，**不要试**"再小心一点内联"

### Pattern B：BOM 导致 bash 报 `/bin/bash: No such file or directory`
**症状**：脚本第一行 `﻿#!/bin/bash` 报错，但其他行能跑。

**根因**：`Set-Content -Encoding UTF8` 在 PowerShell 5.1 默认加 BOM。

**永久修复**：
- 用 `Set-Content -Encoding UTF8 -NoNewline` + 后续用 `[System.IO.File]::WriteAllText(path, content, [UTF8Encoding]::new($false))` 强制无 BOM
- **或者**：直接忽略该第一行报错（后续命令仍会执行），但这会污染输出

### Pattern C：大文件系统无限搜索（无 timeout 无 -maxdepth）
**症状**：`sudo find /tmp/api_mnt -name X` 卡 30 秒-5 分钟，用户取消。

**根因**：
1. `sudo` 弹密码提示，但 WSL-in-PowerShell 无 tty，阻塞
2. 没限深度/超时，大挂载点（几十 GB）全盘扫
3. **更常见**：handover 里**已经有路径**，却还去 find

**永久修复**：
- 🥇 **先查 handover.md**（尤其 §5 "证据路径速查"）再 find
- 🥈 任何 find 加 `-maxdepth 5` 或 `timeout 30 find ...`
- 🥉 **绝不** sudo find（WSL 环境权限通常够；真需要 sudo，用 `echo <pwd> | sudo -S`，但不推荐）

### Pattern D：盲目继续搜索一个"可能不存在"的目标
**症状**：Q49 neo4j 搜了 15 分钟全盘，实际 neo4j 服务在已被删除的 VM 里。

**根因**：没有**证伪假设**就一直找。

**永久修复**：
- 搜索 **10 分钟无关键词命中** → 立刻停，反问"我假设 X 存在，依据是什么？能不能证伪？"
- 题目说"分析 X 的 PC"，但 X 的 PC 没挂 / 没有 X 提到的软件 → 题目可能在别处（如 VM / 容器 / 另一机），跳题

### Pattern E：awk/sed 里 `$` 被 PowerShell 吃掉
**症状**：`awk '{print $3}'` 在 `wsl -e bash -c` 里变成 `awk '{print }'`。

**重复次数**：本会话**至少 4 次**。

**永久修复**：**不要在 PowerShell 里内联 awk/sed**，用 Python 或 `grep -oE` 替代，或走 Pattern A 的脚本文件路线。

---

## 🧭 每次做题前的 3 条预加载规则（"开工清单"）

下次打开 Cascade 做题，第一句自检：

```
1. 我要找的信息，handover.md §5 / knowledge/ / 前轮 worklog 里**有没有**已记的？
2. 我这条命令涉及 bash+PowerShell 嵌套吗？若是 → 写脚本文件
3. 我的搜索目标，如果 10 分钟搜不到，我的备选假设是什么？
```

---

## 📊 本场 FIC 前的**绝对禁律**

1. ❌ 不要在 `wsl -e bash -c` 后跟超过 3 个管道符的内联 bash
2. ❌ 不要用 `sudo` 除非明确记得 sudoers NOPASSWD 配置
3. ❌ 不要 find 无 -maxdepth 的根目录
4. ❌ 不要反复 try 同一个失败了 2 次的方法（换工具）
5. ❌ 不要在没读 handover 的情况下"自己去探索路径"

---

## 🩹 快速修复模板（复制粘贴用）

### 模板 1：需要跑复杂 bash
```powershell
Set-Content -Path 'E:\项目\自动化取证\cases\<赛>\artifacts\<名>.sh' -Encoding UTF8 -NoNewline -Value @'
#!/bin/bash
<BASH 原样贴这里>
'@
wsl -e bash /mnt/e/项目/自动化取证/cases/<赛>/artifacts/<名>.sh
```

### 模板 2：带超时的 find
```bash
timeout 30 find <dir> -maxdepth 5 -iname '<pat>' 2>/dev/null
```

### 模板 3：Python 内联（替代 awk）
```powershell
Set-Content -Path '...artifacts/xx.py' -Encoding UTF8 -Value @'
<Python 脚本>
'@
wsl -e python3 /mnt/e/.../xx.py
```

---

## 📝 累计的"本 repo 已知路径"（handover 的索引）

- 早起王 PC 已挂：`/tmp/zqw_mnt`
- 早起王 apiserver VM（Ubuntu，含 claude-relay-service + Redis dump）：`/tmp/api_mnt`
  - Redis dump: `/tmp/api_mnt/home/zaoqiwang/claude-relay-service/dump.rdb`
  - admin hash: `/tmp/api_mnt/home/zaoqiwang/claude-relay-service/data/init.json`
- 早起王安卓 tar 已解：`/tmp/zqw_phone/`
- 倩倩 PC 内存 dump 已解（本会话）：`/tmp/qq_mem/DESKTOP-3943OKD-20260403-014746.dmp`
  - Vol3 输出：`/tmp/qq_mem_out/`
  - Weixin PID 10892 内存 dump：`/tmp/qq_mem_out/weixin_dump/pid.10892.dmp`
- 倩倩 PC E01：`/mnt/a/2-计算机/倩倩的PC镜像.E01`（**未挂**）
- 早起王 U 盘 dd：`/mnt/a/2-计算机/早起王的U盘.dd`（**未挂**，50MB 小）
- fpt HarmonyOS app 已解：`/tmp/fpt_hap/`
