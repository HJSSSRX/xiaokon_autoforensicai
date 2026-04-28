# 工具清单与安装

只装解决过实际问题的工具。新工具等真正需要时再加。

---

## Windows 端（便携版优先，全部放 `tools/`）

### Eric Zimmerman 套件（Windows 取证黄金标准）

**一键安装**：`powershell -ExecutionPolicy Bypass -File scripts\install_windows_tools.ps1`

该脚本会调用官方 `Get-ZimmermanTools.ps1`，下载 .NET Framework 4 构建到 `tools\EZ\`（无需额外运行时）。

已就绪工具（位于 `tools\EZ\`）：
- `MFTECmd.exe` —— 解析 `$MFT`（文件系统时间线）
- `RECmd\RECmd.exe` —— 注册表 hive 批量查询（附带 BatchExamples 规则库）
- `PECmd.exe` —— Prefetch 解析（程序执行痕迹）
- `LECmd.exe` —— LNK 文件解析
- `JLECmd.exe` —— Jump List 解析
- `EvtxeCmd\EvtxECmd.exe` —— Windows 事件日志（注意目录拼写是 `EvtxeCmd`）
- `SBECmd.exe` —— Shell Bag
- `AmcacheParser.exe` —— Amcache（程序安装痕迹）
- 另有 `AppCompatCacheParser.exe`、`bstrings.exe`、`RBCmd.exe`、`rla.exe`、`SrumECmd.exe`、`SumECmd.exe`

### 7-Zip

`tools\7zip\7zr.exe` —— 只解压 `.7z`。ZIP 用 PowerShell 内置的 `Expand-Archive`。复杂格式走 WSL 的 `7z`。

### Arsenal Image Mounter（免费版）

https://arsenalrecon.com/downloads  
把 E01/dd/vmdk 以只读方式挂成盘符，必要时使用。

### 火眼系列（已有授权）

- 火眼证据分析系统
- 火眼移动取证系统
- 火眼仿真系统

这些是 GUI 工具，作为开源工具搞不定时的人肉后备。**解题时如果需要用到火眼，Cascade 会明确告诉用户"请在火眼XX里做YY操作，然后把导出目录告诉我"。**

---

## WSL2 (Ubuntu) 端

**一键安装**：先安装 WSL（见下），然后在 Ubuntu 内：

```bash
bash /mnt/e/项目/自动化取证/scripts/install_wsl_tools.sh
```

脚本会安装：
- **apt**：`sleuthkit`、`ewf-tools`、`afflib-tools`、`libbde-utils`、`libfsapfs-utils`、`tshark`、`zeek`、`ripgrep`、`jq`、`sqlite3`、`exiftool`、`p7zip-full`
- **pip（venv）**：`aleapp`、`ileapp`、`pandas`、`openpyxl`、`pycryptodome`、`python-evtx`、`pypff`、`volatility3`
- 若系统源有 `plaso-tools` 则附带

venv 位于 `.venv/`，激活：`source /mnt/e/项目/自动化取证/.venv/bin/activate`

### 首次安装 WSL（需管理员）

PowerShell **以管理员身份**运行：

```powershell
wsl --install -d Ubuntu
```

重启后第一次进入 Ubuntu 时设置用户名密码，再跑上面的 `install_wsl_tools.sh`。
