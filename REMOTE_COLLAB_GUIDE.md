# AutoForensicAI · 远程协作完全手册

> 给人类看的版本。读完这一份，就能搞清楚多机协作怎么跑、怎么排错、出问题该看哪儿。
> **最后更新**：2026-05-07

---

## 0. 一分钟原理（图解）

我们做的事情：**让多台不同机器上的 AI 助手（Windsurf / Cursor / Claude Code）一起做一道电子取证题**。

最朴素的实现方式：

```
                ┌─────────────────────────────────┐
                │   你的主机（Windows）             │
                │   ┌─────────────────────────┐   │
                │   │  Hub 服务器             │   │
                │   │  (collab_hub.py)        │   │
                │   │  端口 8765              │   │
                │   │                         │   │
                │   │  下面挂 7 个 YAML 文件：  │   │
                │   │  · findings.yaml         │   │
                │   │  · progress.yaml         │   │
                │   │  · answers.yaml          │   │
                │   │  · questions.yaml        │   │
                │   │  · session_log.yaml      │   │
                │   │  · blockers.yaml         │   │
                │   │  · strategy.yaml         │   │
                │   └─────────────────────────┘   │
                │           ↑↓ HTTP                │
                │   ┌──────┐  ┌──────┐            │
                │   │server│  │binary│  ← 本机两个 AI 角色
                │   └──────┘  └──────┘            │
                └────────────┬────────────────────┘
                             │ HTTP（局域网或 cloudflared 公网隧道）
                ┌────────────┴────────────┐
                ↓                         ↓
        ┌────────────┐              ┌────────────┐
        │ 远程机 1    │              │ 远程机 2    │
        │ 计算机角色  │              │ 手机角色    │
        │ (computer) │              │ (mobile)   │
        └────────────┘              └────────────┘
```

**核心 3 句话**：
1. **每个 AI 角色都是一个独立的 IDE 会话**（你在不同电脑上开了 Windsurf/Cursor 然后粘贴角色 prompt）
2. **它们彼此不直接通信，全部通过 Hub 转发**（像微信群，Hub 是群本身）
3. **Hub 只是一个 HTTP 服务器**，所有数据都存在 7 个 YAML 文件里，关掉 Hub 数据不丢

**为什么不用 GitHub / SMB / Slack 之类的？**
- GitHub：本机 hosts 屏蔽（我们之前踩过坑）+ AI 经常忘记 push
- SMB：跨网段、防火墙、权限地狱
- Slack/钉钉：要 token、要 webhook、外部依赖
- **HTTP Hub**：零依赖，500 行 Python 标准库，AI 一个 `Invoke-RestMethod` 就能用

---

## 1. 三种网络场景（人话版）

### 场景 A：所有机器都在同一个 Wi-Fi 路由器下 ★ 最简单

家里、办公室同一房间、比赛现场连同一个无线 AP，都属于这种。

```
[路由器] ─── WiFi ───┬──→ 主机（Hub 在这）
                    ├──→ 远程机 1（计算机）
                    └──→ 远程机 2（手机分析）
```

**直接用主机的局域网 IP**，比如 `http://192.168.1.10:8765`，远程机就能连。

### 场景 B：远程机在外网，物理隔离 ★ 需要 cloudflared

远程机在出差、家里 WiFi 不一样、4G 流量、公司内网……跨网段彻底连不通。

这时候用 **cloudflared 隧道**：在主机上跑一个 cloudflared 客户端，它会给你一个 `https://xxx.trycloudflare.com` 的公网域名，远程机直接访问这个域名等同于访问本机的 8765 端口。

```
            [互联网]
              ▲
              │ HTTPS
              │
[主机] ────→ [cloudflared 隧道]
   │                ▲
   │                │
  Hub          [远程机]（任意网络）
```

### 场景 C：手机热点串联 ★ 应急

主机和远程机都连主机的手机热点，**等于变成场景 A**。
比赛现场公共 WiFi 不可信、有限速、IP 经常变 → 开自己手机热点最稳。

---

## 2. 启动流程（图文步骤）

### 主机端（你来做的事）

#### Step 1：启动 Hub

打开 PowerShell，复制粘贴：

```powershell
python "E:\项目\自动化取证\tools\collab_hub.py" serve "E:\ffffff-JIANCAI\2026FIC团体赛\case" --port 8765 --bind 0.0.0.0
```

说明：
- `serve` 是子命令
- 后面那个长路径是**当前比赛检材的 case 目录**（每次比赛换一个）
- `--bind 0.0.0.0` 必须加，否则只有本机自己能连
- `--port 8765` 是默认端口，可以改

启动成功你会看到：

```
============================================================
  Collaboration Hub v3  -  port 8765
============================================================
  Case dir:  E:\ffffff-JIANCAI\2026FIC团体赛\case
  Bind:      0.0.0.0:8765

  Remote machines connect via:
    curl http://172.21.161.2:8765/ping
    curl http://192.168.74.1:8765/ping
    ...
```

#### Step 2：找出"对的那个 IP"

Hub 启动会列出本机所有网卡的 IP，但**不是所有 IP 都能让远程机连上**。

| IP 段 | 说明 | 远程机能用吗 |
|---|---|---|
| `192.168.x.x` | 路由器分配的 LAN IP | ✅ **大概率就是这个** |
| `172.16.x.x` 到 `172.31.x.x` | 部分路由器 / 公司网络 LAN | ✅ 可能 |
| `172.27.x.x` | WSL 虚拟网卡 | ❌ 仅 WSL 内能用 |
| `192.168.74.1` / `192.168.223.1` | VMware 虚拟网卡 | ❌ 仅虚拟机用 |
| `127.0.0.1` | 回环地址 | ❌ 仅本机自己 |

**判断方法**：在远程机上 `ping <每个IP>`，能 ping 通的就是对的。

或者更简单：本机 PowerShell 跑 `ipconfig`，找**"无线局域网适配器 WLAN"** 或 **"以太网适配器 以太网"** 下面的 IPv4 地址。

#### Step 3：开 Windows 防火墙

如果远程机能 `ping <IP>` 但 `curl http://<IP>:8765/ping` 失败，**就是防火墙拦了**。

**用管理员权限的 PowerShell** 执行（一次配置永久生效）：

```powershell
New-NetFirewallRule -DisplayName "AutoForensicAI Hub 8765" -Direction Inbound -Protocol TCP -LocalPort 8765 -Action Allow
```

#### Step 4：打开 Dashboard 看实时面板

浏览器访问：`http://127.0.0.1:8765/dashboard`

里面包括：
- 顶部总进度条
- 4 张角色卡片（带状态徽章 + 上次更新时间）
- 题目矩阵（5 类 × N 题，绿格=已答）
- **实时发现流（点击 finding 弹详情，能看到 detail 全文 + 跳转关联 finding）**
- 卡点 + 跨角色问题
- **主设计师决策时间轴**
- **当前策略**

5 秒自动刷新，右上角能切手动模式。

#### Step 5：把 Hub IP 告诉远程机用户

简单地一句话发过去：
```
Hub 地址: http://192.168.1.10:8765
（请先 ping 测试，再用 curl http://192.168.1.10:8765/ping 确认 Hub 可达）
```

---

### 远程机端（远程机用户来做）

#### Step 1：验证 Hub 可达

PowerShell 跑：

```powershell
$Hub = "http://192.168.1.10:8765"   # 替换成主机告诉你的 IP
Invoke-RestMethod "$Hub/ping"
```

期望输出：
```
status version time
------ ------- ----
ok     v3      2026-05-07 15:30:00
```

如果失败 → 看本手册第 5 节"故障排查"。

#### Step 2：从 Hub 下载你的角色 prompt

```powershell
# 计算机取证角色（远程机1）
Invoke-RestMethod "$Hub/files/role_prompt_computer.md" | Out-File -Encoding utf8 "$env:TEMP\role_prompt_computer.md"

# 手机取证角色（远程机2）
Invoke-RestMethod "$Hub/files/role_prompt_mobile.md" | Out-File -Encoding utf8 "$env:TEMP\role_prompt_mobile.md"
```

#### Step 3：粘贴 prompt 给 IDE AI

打开 Windsurf / Cursor / Claude Desktop，新建会话，把整个 `role_prompt_*.md` 内容粘到对话框。

**告诉 AI 一句话**：
> Hub 地址是 http://192.168.1.10:8765，请先执行 prompt 里"启动时必做"的命令验证连通

#### Step 4：（可选）打开 Dashboard

远程机的浏览器：`http://192.168.1.10:8765/dashboard`

跟主机看的内容**完全一样**，能实时看到全队进度。

---

## 3. cloudflared 公网隧道（场景 B 必看）

当远程机和主机不在同一局域网，**唯一的方法就是用隧道**。我们用 [cloudflared](https://github.com/cloudflare/cloudflared)。

### 3.1 安装（仅主机要装）

下载 `cloudflared-windows-amd64.exe`：
- 官网：https://github.com/cloudflare/cloudflared/releases/latest
- 放到 `C:\Program Files (x86)\cloudflared\cloudflared.exe`

### 3.2 启动隧道（带日志的正确写法）

⚠️ **千万不要直接用 `cloudflared tunnel --url http://localhost:8765`**，因为它的输出会刷在终端窗口里，**关掉 PowerShell 那个 URL 就找不回来了**！

**正确写法（重定向 stdout 到日志文件）**：

```powershell
$logDir = "E:\项目\自动化取证\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Start-Process `
    -FilePath "C:\Program Files (x86)\cloudflared\cloudflared.exe" `
    -ArgumentList "tunnel","--url","http://localhost:8765" `
    -RedirectStandardOutput "$logDir\cloudflared.out.log" `
    -RedirectStandardError "$logDir\cloudflared.err.log" `
    -WindowStyle Hidden

# 等待 8 秒让 cloudflared 建立连接
Start-Sleep -Seconds 8

# 提取 URL
$url = Get-Content "$logDir\cloudflared.err.log" | Select-String "https://.*trycloudflare.com" | ForEach-Object {
    if ($_ -match "https://[a-z0-9-]+\.trycloudflare\.com") { $matches[0] }
} | Select-Object -First 1
"远程机用这个 URL 访问 Hub："
$url
```

> cloudflared 的 URL 实际打印在 **stderr** 里（不是 stdout），所以要看 `.err.log`。

把脚本保存为 `E:\项目\自动化取证\scripts\start_cloudflared.ps1`，下次一键启动。

### 3.3 当前 cloudflared URL 怎么找回（如果忘了）

如果 cloudflared 已经在跑但你忘了 URL：

#### 方法 A：从远程机问回来 ★ 最快

远程机 2 的 AI 会话里，让用户问它："你当前用的 Hub URL 是什么？"
AI 会从对话历史里找到最初设置的 `$Hub` 变量值。

#### 方法 B：从日志找

如果当时启动用了正确写法（见 3.2）：
```powershell
Get-Content "E:\项目\自动化取证\logs\cloudflared.err.log" | Select-String "trycloudflare.com" | Select-Object -First 3
```

#### 方法 C：重启 cloudflared（最后手段）

⚠️ **会换新 URL！远程机 2 会暂时失联，必须把新 URL 重新告诉它！**

```powershell
Get-Process cloudflared | Stop-Process -Force
# 然后按 3.2 的脚本重启
```

### 3.4 远程机怎么用 cloudflared URL

跟用 LAN IP **完全一样**，只是 `$Hub` 变量值不同：

```powershell
$Hub = "https://shy-cat-1234.trycloudflare.com"   # 主机给你的 cloudflared URL
Invoke-RestMethod "$Hub/ping"
Invoke-RestMethod "$Hub/files/role_prompt_mobile.md"
# 之后所有 API 调用照常
```

---

## 4. 实时 Dashboard 使用指南

### 4.1 打开方式

| 你在哪台机器 | 浏览器地址 |
|---|---|
| 主机 | `http://127.0.0.1:8765/` |
| 同 WiFi 远程机 | `http://<主机LAN IP>:8765/dashboard` |
| 跨网段远程机 | `<cloudflared URL>/dashboard` |

### 4.2 面板说明

```
┌─────────────────────────────────────────────────────────────────┐
│ 标题                  ● Hub 已连接  上次刷新:21:55  [自动 5s ●]   │
├─────────────────────────────────────────────────────────────────┤
│ 总进度    27/52 (51.9%)                                           │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░                    │
├──────────────────┬──────────────────┬──────────────────┬─────────┤
│ 💤 计算机        │ ✅ 手机           │ ⏸ 服务器          │ 🟡 二进制│
│ idle/done...    │ 17 完成 0 待办    │ 7 完成 10 待办   │ 2 完成  │
│ 上次:5s前        │ 上次:33min 前     │ 上次:6h 前       │ ...     │
│ 当前任务:...     │ 所有17题已解出     │ Q2-Q15阻塞LVM    │         │
└──────────────────┴──────────────────┴──────────────────┴─────────┘
┌─────────────────────────────────────────────────────────────────┐
│ 题目矩阵 (绿=已答 / 灰=未答 / hover 看答案)                        │
│ 计算机 │ ◻ ◻ ◻ ◻ ◻ ◻ ◻ ◻ ◻ ◻              0/10 (0%)            │
│ 手机   │ ✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅            17/17 (100%)         │
└─────────────────────────────────────────────────────────────────┘
┌──────────────────────────────────┬──────────────────────────────┐
│ 实时发现流（点击看详情）          │ 卡点 & 跨角色问题             │
│ 21:53 [F-C011] 计算机 vc 容器... │ B001 server LVM 解密阻塞     │
│ 21:13 [F-M017] 手机   备用域名   │ Q002 binary→server 钱包问题  │
│ ...                              │ ...                          │
├──────────────────────────────────┼──────────────────────────────┤
│ 主设计师决策时间轴                │ 当前策略                      │
│ ● 21:30 入库 20 个高置信答案     │ Phase 4: 等待 KDF 回复       │
│ ● 21:00 mobile 全部完成          │ 优先级: vc 解密 / Q3 password│
│ ...                              │ 延后: 计算机 Q10 暴破        │
└──────────────────────────────────┴──────────────────────────────┘
```

### 4.3 角色卡片状态颜色

- **绿色边框**：状态 done，正常完成
- **黄色边框**：超过 2 小时没更新（可能在分析中没顾上 POST 进度）
- **红色边框**：超过 6 小时没更新（极可能离线/卡死）
- **彩色徽章**：💤 idle / 🟡 in_progress / ⏸ paused / ✅ done / 🔴 blocked

### 4.4 点击交互

- **点击 finding 卡片** → 弹出详情 modal（看 summary + detail + related_to 关联）
- **点击 modal 里的紫色 F-XXX 标签** → 跳转到关联的 finding（适合追线索链）
- **按 Esc 键** 关闭 modal

---

## 5. 故障排查（按现象查）

### 现象 1：远程机 ping 不通主机 IP

| 可能原因 | 解决 |
|---|---|
| 不在同一局域网 | 让两台机器连同一 WiFi，或主机开手机热点 |
| 主机 IP 给错了 | 重新跑 `ipconfig` 找对的那个 |
| 主机断网了 | 看主机网络图标 |

### 现象 2：能 ping 通但 `curl` 不通

**99% 是防火墙**：用管理员 PowerShell 执行第 2 节 Step 3 的防火墙命令。

### 现象 3：远程机 AI 已经看到其他角色的 finding，但主面板上它的卡片显示"上次:从未"

**原因**：AI 只 GET 没 POST 过 `/progress/<role>`。

**解决**：在远程机的 IDE 会话里告诉 AI：
> 请立即 POST 一次 progress 到 Hub，告诉大家你正在做什么。

或者直接给 AI 这段命令模板：
```powershell
$body = @{
  status="in_progress"
  current_task="正在分析 ..."
  completed=@()
  pending=@("Q1","Q2","Q3")
} | ConvertTo-Json
Invoke-RestMethod "$Hub/progress/computer_analyst" -Method POST -Body $body -ContentType "application/json"
```

### 现象 4：cloudflared URL 找不回来了

参见第 3.3 节，三种方法。**首选方法 A：从远程机问回来**。

### 现象 5：POST 报 400 "Invalid JSON body"

**原因**：PowerShell JSON 引号转义问题。

**禁止**：手写 JSON 字符串
```powershell
# ❌ 错的
Invoke-RestMethod "$Hub/findings" -Method POST -Body '{"from":"computer_analyst","summary":"..."}'
```

**正确**：用 hashtable + ConvertTo-Json
```powershell
# ✅ 对的（仅纯 ASCII）
$body = @{ from="computer_analyst"; summary="..." } | ConvertTo-Json
Invoke-RestMethod "$Hub/findings" -Method POST -Body $body -ContentType "application/json"
```

### 现象 5b：中文字段提交后变成 `?`（**v3.1 重要**）

**症状**：POST 时带中文 `analysis`、`summary`、`verify_note` 等，Hub 拿到后中文全变 `?`。

**根因**：PowerShell `ConvertTo-Json` 默认用 ASCII 编码 → `Invoke-RestMethod` 又默认按 ASCII 发送 body → Hub 用 UTF-8 解码看到的是垃圾。

**解决方案 3 选 1**：

**A（最推荐）**：用 Python urllib 提交：
```python
import urllib.request, json
body = {"category":"...", "qid":"...", "analysis":"中文解析..."}
data = json.dumps(body, ensure_ascii=False).encode("utf-8")
req = urllib.request.Request("http://127.0.0.1:8765/answers",
    data=data,
    headers={"Content-Type":"application/json; charset=utf-8"},
    method="POST")
urllib.request.urlopen(req)
```

**B**：PowerShell 强制 UTF-8 字节：
```powershell
$body = @{ analysis="中文解析" } | ConvertTo-Json -Compress
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-RestMethod "$Hub/answers" -Method POST -Body $bytes `
    -ContentType "application/json; charset=utf-8"
```

**C**：写临时文件 + curl.exe：
```powershell
@{ analysis="中文" } | ConvertTo-Json | Out-File -Encoding utf8NoBOM tmp.json
curl.exe -X POST "$Hub/answers" -H "Content-Type: application/json" --data-binary "@tmp.json"
```

**自检**：POST 后 GET 同一条记录看中文有没有变 `?`：
```powershell
Invoke-RestMethod "$Hub/answers/mobile_forensics/Q1" | ConvertTo-Json -Depth 3
```

### 现象 6：Hub 进程意外退出

**症状**：Dashboard 红色 "Hub 不可达"

**自检**：
```powershell
Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    (Get-WmiObject Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine -like "*collab_hub*"
}
```

如果没结果 → Hub 挂了 → 重启（数据无损，YAML 文件还在）。

### 现象 7：Dashboard 改了但浏览器还是旧的

**原因**：浏览器缓存。

**解决**：Ctrl+F5 强刷。

---

## 6. 数据流原理（深入版）

### 6.1 7 个共享 YAML 文件

所有"状态"都存在 `case/shared/*.yaml`，Hub 读写它们：

| 文件 | 内容 | 谁写 | 谁读 |
|---|---|---|---|
| `findings.yaml` | 各角色发现的证据，按 `F-X001` 编号 | 任何角色 POST `/findings` | 所有人 |
| `progress.yaml` | 每个角色的当前任务 + 已完成 + 待办 | 角色 POST `/progress/<role>` | 主设计师 + Dashboard |
| `answers.yaml` | 题目最终答案，按类别+qid 分组 | 主设计师 POST `/answers` | 任何人 |
| `questions.yaml` | 跨角色提问 / 回复 | 任何角色 POST `/questions` | 收件方角色 |
| `session_log.yaml` | 主设计师决策日志 | 主设计师 POST `/session/log` | Dashboard 时间轴 |
| `blockers.yaml` | 角色卡点（求助清单） | 角色 POST `/session/blocker` | 主设计师路由 |
| `strategy.yaml` | 当前策略（阶段+优先级） | 主设计师 POST `/session/strategy` | 所有人参考 |

### 6.2 一个典型协作回合

```
[14:00] mobile 角色拿到 prompt → IDE 启动 → 第一次 GET /ping → ✓
[14:01] mobile 拉态势 GET /findings + /progress + /session
[14:02] mobile 开始解 Q1 → 解出 → POST /findings  → Hub 给 ID F-M001
[14:03] Dashboard 自动刷新 → "实时发现流"出现 F-M001
[14:04] mobile 解题中遇阻 → POST /session/blocker → 卡点列表多一条
[14:05] 主设计师看到卡点 → 判断这事 binary 角色见过 → POST /questions {to=binary, ...}
[14:06] binary GET /questions?to=binary_analyst 看到收件箱 → 回复 → POST /questions/Q001/reply
[14:07] mobile GET /questions?from=mobile_analyst 看到回复 → 解出 → POST 答案
[14:08] 主设计师 POST /answers 把答案入库 → 跑 sync_kb.py
[14:08] knowledge/competitions/2026FIC-团体赛/MASTER_SHEET.md 自动更新
```

### 6.3 为什么这样设计

- **角色无状态**：每个 AI 只读 prompt + 调 API，重启 IDE 不丢任何数据
- **Hub 无业务逻辑**：只是 YAML 文件 ↔ HTTP 的胶水，500 行
- **CRUD 全异步**：没有锁，没有队列，靠 Hub 内部线程锁保证 YAML 写入原子性
- **完全离线友好**：本机断网照样跑（远程机连不上而已，不影响本机角色）

---

## 7. 一页速查表

### 主机日常操作

```powershell
# 启动 Hub（每次开赛 / 重启电脑后做一次）
python "E:\项目\自动化取证\tools\collab_hub.py" serve "<case_dir>" --port 8765 --bind 0.0.0.0

# 启动 cloudflared（如果远程机跨网段）
Start-Process "C:\Program Files (x86)\cloudflared\cloudflared.exe" `
    -ArgumentList "tunnel","--url","http://localhost:8765" `
    -RedirectStandardError "E:\项目\自动化取证\logs\cloudflared.err.log" `
    -WindowStyle Hidden

# 看 cloudflared URL
Get-Content "E:\项目\自动化取证\logs\cloudflared.err.log" | Select-String "trycloudflare.com"

# 看 Dashboard
Start-Process "http://127.0.0.1:8765/dashboard"

# 同步知识库（POST 答案后必跑）
python "E:\项目\自动化取证\tools\sync_kb.py"

# 看进度
Invoke-RestMethod "http://127.0.0.1:8765/progress" | ConvertTo-Json -Depth 5

# 看所有 finding
Invoke-RestMethod "http://127.0.0.1:8765/findings" | Select-Object -Last 10
```

### 远程机用户日常操作

```powershell
$Hub = "http://192.168.1.10:8765"   # 或 cloudflared URL

# 检查 Hub 可达
Invoke-RestMethod "$Hub/ping"

# 看自己角色的态势
Invoke-RestMethod "$Hub/findings"
Invoke-RestMethod "$Hub/questions?to=computer_analyst"

# 看 Dashboard
Start-Process "$Hub/dashboard"
```

### 关键文件路径

| 文件 | 作用 |
|---|---|
| `E:\项目\自动化取证\tools\collab_hub.py` | Hub 服务器 |
| `E:\项目\自动化取证\tools\dashboard.html` | Dashboard 网页 |
| `E:\项目\自动化取证\tools\sync_kb.py` | 知识库同步脚本 |
| `E:\项目\自动化取证\prompts\role_prompt_*.md` | 4 个角色的 prompt |
| `E:\项目\自动化取证\prompts\main.md` | 主设计师 prompt |
| `E:\项目\自动化取证\knowledge\competitions\<赛事名>\` | 赛事归档（永久资产） |
| `<case_dir>\shared\*.yaml` | 7 个状态文件（赛事临时数据） |

---

## 8. 一句话总结

> **主机**：跑 Hub → 配防火墙 → 把 IP 给远程机 → 看 Dashboard
> **远程机**：ping 测 → curl /ping → 拉 prompt → 喂给 IDE AI → 看 Dashboard
> **跨网段**：主机加跑 cloudflared → 用 trycloudflare.com URL 替代 LAN IP
> **数据全在 YAML**：Hub 重启不丢，机器重启不丢，跨机器复盘只要一份 case/shared/

---

## 附录：相关文档

- `prompts/main.md` — 主设计师（小空）prompt，含 Phase 0~4 完整流程
- `prompts/role_prompt_*.md` — 4 角色 prompt，含 Hub API 命令模板
- `case/REMOTE_DEPLOYMENT.md` — 偏技术的远程机部署手册（更详细的 API 参数）
- `knowledge/competitions/2026FIC-团体赛/README.md` — 当前赛事归档入口
- `HANDOFF_COLLAB_V3.md` — v3 协作架构设计交接文档（历史决策原因）
