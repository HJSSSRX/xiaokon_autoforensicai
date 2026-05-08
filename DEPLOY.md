# 快速部署指南（xiaokon-all 一站式）

> 这是 **AutoForensicAI / 小空 / ForHacker** 项目的统一全量仓库。
> 包含所有内容：框架代码 + 知识库 + 解题方案 + 工具脚本。
> Clone 一次，开干。

---

## 仓库定位

`xiaokon-all` 是项目的**统一发布仓库**：

| 仓库 | 用途 |
|---|---|
| **xiaokon-all** (本仓库) | 完整全量，给新用户/部署者用 |
| xiaokon_autoforensicai | 历史骨架仓库（仅框架代码） |
| autoforensicai_data | 历史数据仓库（仅知识库） |

历史的双仓架构是迁移期保留——**新用户只需要 clone xiaokon-all**。

---

## 5 分钟部署

### Step 1: 克隆

```powershell
git clone https://github.com/HJSSSRX/xiaokon-all.git
cd xiaokon-all
```

### Step 2: 一键安装工具链（42 个取证/逆向/渗透工具）

```powershell
# 完整安装（推荐）
.\install.ps1

# 仅检查（不安装），看哪些已经有/缺失
.\install.ps1 -Check

# 按角色安装（节省时间）
.\install.ps1 -Role forensics       # 取证类
.\install.ps1 -Role pentest         # 渗透类
.\install.ps1 -Role reverse         # 逆向类
.\install.ps1 -Role stego_crypto    # 隐写/密码类

# 加上 WSL 工具（steghide / foremost / john / hydra...）
.\install.ps1 -WSL

# 加上 Docker 镜像（Kali / REMnux / SIFT）
.\install.ps1 -Docker
```

完整工具列表见 `@e:\项目\自动化取证\tools\manifest.yaml`，安装清单源自 `@e:\项目\自动化取证\install.ps1`。

### Step 3: 启动协作 Hub（多 AI 协作的核心）

```powershell
# 启动 HTTP Hub (端口 8765, 听 0.0.0.0 让 LAN/远程机可连)
python tools\collab_hub.py serve <案件目录> --port 8765 --bind 0.0.0.0

# 例:
python tools\collab_hub.py serve E:\my-case --port 8765 --bind 0.0.0.0
```

启动后访问：
- **API**: `http://127.0.0.1:8765/ping`
- **Dashboard（队长视角）**: `http://127.0.0.1:8765/dashboard`

### Step 4: 让 AI 接管 — 在 IDE chat 输入

```
小空自己动
```

AI 会读取 `prompts/main.md` 进入"小空（主设计师）"模式，开始分析证据、分配角色、生成 prompt。

详细工作流见 `@e:\项目\自动化取证\README.md` 与 `@e:\项目\自动化取证\REMOTE_COLLAB_GUIDE.md`。

---

## 远程多机协作（可选）

需要多台机器协同（例如：本机跑 server/binary，远程 1 跑 computer，远程 2 跑 mobile），看：

- **本机部署**: `@e:\项目\自动化取证\REMOTE_COLLAB_GUIDE.md`
- **远程机加入**: `@E:\ffffff-JIANCAI\2026FIC团体赛\case\REMOTE_DEPLOYMENT.md`（每个案件目录会有一份）
- **PowerShell 中文 UTF-8 陷阱**: REMOTE_COLLAB_GUIDE 第 5b 节（**必读**）

---

## 目录结构

```
xiaokon-all/
├── prompts/                    # 角色 prompt（main.md = 主设计师 / role_prompt_*.md = 各分析师）
├── tools/                      # 框架代码 + 工具
│   ├── collab_hub.py           # HTTP 协作 Hub (v3.1)
│   ├── dashboard.html          # Dashboard 主页
│   ├── sync_kb.py              # Hub state → MASTER_SHEET 同步
│   ├── manifest.yaml           # 工具清单（install.ps1 读取）
│   ├── tool_status.py          # 工具状态检查
│   ├── backfill_answers.py     # finding → answer 翻译（主设计师常用）
│   ├── inspect_hub.py          # Hub 状态快照
│   ├── check_remote_alive.py   # 检查远程角色心跳
│   └── ...
├── knowledge/                  # 知识库（合并自原 autoforensicai_data 仓库）
│   ├── solved/                 # 解题方案（含 2022/2024/2026 长安杯+FIC 全套）
│   ├── skills/                 # 角色速查 + Volatility/注册表/WebShell/宝塔等手册
│   ├── cards/                  # 工具卡片
│   ├── wp_index/               # 比赛题目索引
│   └── competitions/           # 当前/历史比赛实时主表（2026FIC 等）
├── tests/                      # 测试
├── install.ps1                 # 一键工具安装
├── README.md                   # 项目主页
├── DEPLOY.md                   # 本文件
├── REMOTE_COLLAB_GUIDE.md      # 远程协作指南
└── REMOTE_PULL_v3.1.md         # 升级到 v3.1 的远程机指令
```

---

## 常见问题

### Q1: 我已经 clone 了旧的 xiaokon_autoforensicai，要换仓库吗

不必。新仓库内容是历史骨架的超集（multiplied 知识库），但骨架仓库仍然是同步的（同 commit）。如果你想换：

```powershell
git remote set-url origin https://github.com/HJSSSRX/xiaokon-all.git
git pull
```

### Q2: install.ps1 失败怎么办

```powershell
# 1. 看哪些工具状态
python tools\tool_status.py --missing

# 2. 单独安装某个工具
scoop install <名字>             # 或
pip install <名字>               # 或
winget install <id>

# 3. 跳过 fail 的工具继续
.\install.ps1 -Force
```

### Q3: 不想用 scoop / 公司不让装怎么办

把 `tools/manifest.yaml` 里的 `known_paths` 字段填上你手动安装的路径，`tool_status.py` 会自动识别。

### Q4: Dashboard 打不开

```powershell
# 1. 看 Hub 进程
Get-Process python | Where-Object { (Get-WmiObject Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine -like "*collab_hub*" }

# 2. 测 ping
Invoke-RestMethod http://127.0.0.1:8765/ping

# 3. 防火墙 (LAN 模式需要)
netsh advfirewall firewall add rule name="ForHacker Hub" dir=in action=allow protocol=TCP localport=8765
```

### Q5: 远程机用不了

主机给远程机分发 cloudflared 隧道 URL：

```powershell
# 主机
cloudflared tunnel --url http://127.0.0.1:8765
# 复制输出里 https://xxx.trycloudflare.com 给远程机
```

远程机把 `$Hub` 设为这个 URL 就行：

```powershell
$Hub = "https://xxx.trycloudflare.com"
Invoke-RestMethod "$Hub/ping"
```

---

## 学到了什么

如果你是**新用户**，建议读这个顺序：

1. `@e:\项目\自动化取证\README.md` — 理念
2. `@e:\项目\自动化取证\DEPLOY.md`（本文件）— 部署
3. `@e:\项目\自动化取证\prompts\main.md` — 主设计师工作流（理解小空的"决策模型"）
4. `@e:\项目\自动化取证\REMOTE_COLLAB_GUIDE.md` — 多机协作模式
5. `@e:\项目\自动化取证\knowledge\solved\` 里随便挑几个解题方案 — 看实战是怎么打的

如果你是**老用户**升级到 v3.1，看 `@e:\项目\自动化取证\REMOTE_PULL_v3.1.md`。
