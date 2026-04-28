# TRANSFER_GUIDE — 迁移到新 Win11 + Windsurf 电脑

> **目标**：在一台全新的 Win11 机器上，用 30-60 分钟让我（Cascade）达到**与原机等效的工作能力**。
>
> 前置：新机器已安装 [Windsurf](https://windsurf.com/) 并能登录账号。

---

## 🎯 迁移的"最小能力单元"

要搬走的 3 样东西：

| # | 资产 | 位置 | 大小 | 必选 |
|---|------|------|------|------|
| 1 | 项目代码/文档/脚本 | `E:\项目\自动化取证\` 除 `tools\` 和 `cases\` 外全部 | ~5 MB | ✅ |
| 2 | Karpathy 准则 | `E:\项目\andrej-karpathy-skills-main\` | ~50 KB | ✅ |
| 3 | Windsurf 全局规则 | 用户已保存在 memory（账号级同步） | - | 自动 |

`tools\`（Zimmerman 套件等）和 `cases\`（检材）在新机器上重新拉取/放置。

---

## 🚀 一键部署流程（推荐）

### 步骤 A：在**新机器**上以**管理员**打开 PowerShell

```powershell
# 1. 安装 WSL（如未装）
wsl --install -d Ubuntu
# 重启后首次进入 Ubuntu 设置用户名密码
```

### 步骤 B：同步项目代码

**方式 1：U 盘/网盘**
把 `E:\项目\` 整个目录（除 `自动化取证\cases\` 和 `自动化取证\.venv\`）拷贝到新机同名位置。

**方式 2：Git（推荐长期用）**
在原机器：
```powershell
cd E:\项目\自动化取证
git init; git add .; git commit -m "init"
git remote add origin <你的私有 repo url>
git push -u origin main
```
新机器：
```powershell
git clone <repo> E:\项目\自动化取证
```

同样把 `E:\项目\andrej-karpathy-skills-main\` 也搬过去（可选从 GitHub 重新 clone）。

### 步骤 C：一键装环境

```powershell
# 在新机器的非管理员 PowerShell 里
cd E:\项目\自动化取证
powershell -ExecutionPolicy Bypass -File scripts\bootstrap_new_machine.ps1
```

脚本会：
1. 调 `install_windows_tools.ps1` 下载 Zimmerman 套件到 `tools\EZ\`
2. 在 WSL 内跑 `install_wsl_tools.sh` 装 sleuthkit / tshark / volatility3 等
3. 装额外取证工具：`dnSpy`、`MemProcFS`（放 `tools\`）
4. 创建 `.venv-path` 指针
5. 跑 `scripts\env_healthcheck.sh` 验证

### 步骤 D：Windsurf 端设置

新机器的 Windsurf 里登录用户账号后，**全局规则（Karpathy 准则 + 中文对话）会自动同步**。

若未同步，手动把 `E:\项目\andrej-karpathy-skills-main\CLAUDE.md` 内容粘到 Windsurf 的 Global Rules 里。

### 步骤 E：验证

打开 Windsurf，新建对话，输入：
```
@SESSION_START.md 做了哪几件事？
```
如果 AI 能解释"开场 5 步"，迁移成功。

---

## 🧾 清单：迁移后必须存在的文件

```
E:\项目\自动化取证\SESSION_START.md
E:\项目\自动化取证\PLAYBOOK.md
E:\项目\自动化取证\TRANSFER_GUIDE.md   (本文件)
E:\项目\自动化取证\THREE_MACHINE_SOP.md
E:\项目\自动化取证\WP_FORMAT.md
E:\项目\自动化取证\KARPATHY_GUIDELINES.md
E:\项目\自动化取证\scripts\bootstrap_new_machine.ps1
E:\项目\自动化取证\scripts\install_wsl_tools.sh
E:\项目\自动化取证\scripts\install_windows_tools.ps1
E:\项目\自动化取证\scripts\env_healthcheck.sh
E:\项目\自动化取证\scripts\env_healthcheck.ps1
E:\项目\自动化取证\tools\EZ\MFTECmd.exe  (≥9个 Zimmerman 工具)
E:\项目\自动化取证\tools\EZ\RECmd\RECmd.exe
```

WSL 内：
```
~/.venv-forensics/bin/activate     Python venv
命令：fls, mmls, tsk_recover, ewfmount, tshark, aleapp, vol, rg, jq, sqlite3
```

---

## ⚠️ 新机器常见坑

| 坑 | 症状 | 解决 |
|----|------|------|
| WSL 无网 | `apt update` 超时 | 在 Windows 上打开 `Windows 功能` 确认「虚拟机平台」勾选 |
| 中文路径 `/mnt/e/项目/` 读不到 | 路径含高位字符 | 在 WSL `/etc/wsl.conf` 加 `[automount]\noptions="metadata,uid=1000,gid=1000,umask=022"` 重启 WSL |
| Zimmerman 工具装不上 .NET | 运行 exe 报错 | 脚本已用 `-NetVersion 4`（Win 自带 Framework 4），应该不会碰到 |
| 检材 A 盘不存在 | `ls /mnt/a/` 空 | 新机器没挂 A 盘，用户需要先手动把检材盘接入并分配为 A:\ |
| Windsurf 读不到全局规则 | AI 表现和原机不一样 | 登录状态检查；最坏手动复制 `KARPATHY_GUIDELINES.md` 内容到规则 |
