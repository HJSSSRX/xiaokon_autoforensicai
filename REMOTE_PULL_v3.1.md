# v3.1 升级：远程机一键 pull 指令

> commit `d559f62` · 2026-05-07
> 主要变化：Hub 升级到 v3.1（`/answers` 加 analysis/evidence_path/verification_status），Dashboard 加主表，文档加 PowerShell UTF-8 陷阱说明。

---

## 谁需要 pull

| 角色 | 是否需要 pull | 理由 |
|---|---|---|
| **本机主设计师**（你） | ✅ 已自动同步 | 改动都在这台机器 |
| **本机 server_analyst** | ✅ 必 pull | 共享同一个 git 工作区 |
| **本机 binary_analyst** | ✅ 必 pull | 共享同一个 git 工作区 |
| **远程机 1 — computer_analyst** | 🟡 推荐 pull | 看新版 `REMOTE_COLLAB_GUIDE.md`（含 UTF-8 修复） |
| **远程机 2 — mobile_analyst** | 🟡 推荐 pull | 同上 |

**关键事实**：远程机 AI 分析师不直接调用 `tools/*.py` —— 它们只用 `Invoke-RestMethod` 或 `curl` 调 Hub HTTP 接口。所以**远程机 pull 与否不影响协作能力**，只是为了：

1. 远程机的人类用户能看到 `REMOTE_COLLAB_GUIDE.md` 里新增的 §5b（PowerShell 中文 UTF-8 坑修复）
2. 万一本机宕机，远程机能跑 `tools/collab_hub.py` 接管 Hub 角色

---

## 远程机 pull 步骤（PowerShell）

```powershell
# 假设远程机也在 e:\项目\自动化取证\（按双仓架构）
cd "e:\项目\自动化取证"

# 1. 看本地是否有未提交改动（应该没有，因为远程机 AI 不写本地文件）
git status

# 2. 从骨架仓库拉新版本
git fetch origin
git log --oneline HEAD..origin/main    # 看一下要拉哪些提交
git pull origin main

# 3. 验证关键文件已更新
Get-Item tools\collab_hub.py, tools\dashboard.html, REMOTE_COLLAB_GUIDE.md |
    Select-Object Name, LastWriteTime, Length

# 4. （可选）拉一下数据仓库（如果远程机也有 autoforensicai_data 镜像）
if (Test-Path "e:\项目\autoforensicai_data\.git") {
    git -C "e:\项目\autoforensicai_data" pull origin main
}
```

---

## 远程机分析师的行为变化（**必读**）

### ⚠ 立即生效：所有 POST 中文必须用 UTF-8 字节

之前你直接 `Invoke-RestMethod -Body $body` 提交带中文的 JSON，Hub 收到的中文是 `?`。

**现在请改用以下方法之一**（详见新版 `REMOTE_COLLAB_GUIDE.md` §5b）：

#### 方法 A（推荐）：Python urllib

```python
import urllib.request, json
body = {"from": "mobile_analyst", "summary": "中文摘要", "details": "..."}
data = json.dumps(body, ensure_ascii=False).encode("utf-8")
req = urllib.request.Request("http://hub-host:8765/findings",
    data=data,
    headers={"Content-Type": "application/json; charset=utf-8"},
    method="POST")
urllib.request.urlopen(req)
```

#### 方法 B：PowerShell 强制 UTF-8 字节

```powershell
$body = @{ from="mobile_analyst"; summary="中文摘要" } | ConvertTo-Json -Compress
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-RestMethod "$Hub/findings" -Method POST -Body $bytes `
    -ContentType "application/json; charset=utf-8"
```

**自检**：POST 后立刻 GET 同一条记录，看中文是不是变 `?`：
```powershell
Invoke-RestMethod "$Hub/findings" | Where-Object { $_.from -eq 'mobile_analyst' } |
    Select-Object -Last 1 | ConvertTo-Json -Depth 3
```

> 当前 `server_analyst` 已经踩这个坑：F-S006 之后 14 条 finding 全部中文成 `?`。pull 后请用方法 A 重 POST 修复，或者主设计师会在合适时机做 backfill。

---

## 现在团队真正阻塞在哪（仍未解决）

| # | 阻塞点 | 谁能解 | 怎么解 |
|---|---|---|---|
| 1 | **vc 容器 16 字符 ASCII 密码暴破**（SHA1=`3e627d9046481366eef9c89183f87004968363d9`） | binary（已就绪） + mobile + computer | mobile 重 dump 笔记/相册找 16 字符串；computer 翻浏览器/KeePass/bash_history |
| 2 | **server LV root dm-crypt 解密** | server | 找 keyfile 或装 binary key (Q2/Q4/Q6/Q7-Q15 全部依赖此) |
| 3 | **Q5（虚拟币收款总金额）** | binary（依赖 Q3 解密成功） | Q3 解决后查 VHD 内 wallet/transactions |

主设计师已用 `tools/backfill_answers.py` 把 **computer 10/10 + binary 5/5** 入库（部分占位等突破）。剩 12 题（server 10 + internet 2）。

---

## 看一眼新主表（队长视角）

打开 http://hub-host:8765/dashboard，主屏现在直接是 52 题主表：

- 行点击展开看完整 analysis + evidence_path
- 行尾 ✓?✗ 按钮一键改验证状态（POST `/answers/{cat}/{qid}/verify`）
- 顶部筛选: 全部/已答/未答/已验证/未验证/争议
- 心跳指示器（左上角小绿点呼吸）证明面板在跑
- Hub 重启时弹橙色 banner 12 秒
- 新 finding 来时来源角色卡片闪绿色 1.5 秒

---

## 如果你要把数据同步到 autoforensicai_data 仓库

按双仓架构（参考全局 memory），生成产物归数据仓：

```powershell
# 把骨架仓库新生成的 knowledge/competitions/ 同步到数据仓库
Copy-Item -Recurse `
    "e:\项目\自动化取证\knowledge\competitions" `
    "e:\项目\autoforensicai_data\knowledge\" `
    -Force

# 提交数据仓库
git -C "e:\项目\autoforensicai_data" add -A
git -C "e:\项目\autoforensicai_data" commit -m "sync 2026FIC competitions/ from skeleton"
git -C "e:\项目\autoforensicai_data" push
```

> 我没自动执行这一步——等你确认数据仓库要不要 push 现场比赛数据再决定。
