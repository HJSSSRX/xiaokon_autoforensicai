#Requires -Version 5.1
<#
Purpose : 打包"自动化取证"项目给队友（清理版）。
          自动剔除 cases/ (含敏感数据) 和 tools/ (体积大，重装)。
          保留 .windsurf/ (项目级规则) + roles/ + modes/ + scripts/ + 所有文档。

Usage   : powershell -ExecutionPolicy Bypass -File scripts\pack_for_teammate.ps1
          [-OutDir 'E:\分发'] [-IncludeKarpathy]
#>

[CmdletBinding()]
param(
    [string]$OutDir = 'E:\分发',
    [switch]$IncludeKarpathy   # 把外部 Karpathy 指南也塞进包里
)

$ErrorActionPreference = 'Stop'
$ProjRoot = Split-Path $PSScriptRoot -Parent
$ParentDir = Split-Path $ProjRoot -Parent   # E:\项目\
Write-Host "[*] 项目根: $ProjRoot" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$ts = (Get-Date).ToString('yyyyMMdd-HHmm')
$pkgName = "自动化取证-分发-$ts"
$pkgDir  = Join-Path $OutDir $pkgName

# -------------------------------------------------------------------
# 1. 先做一个 staging 目录（从项目根 robocopy 过来）
# -------------------------------------------------------------------
Write-Host "[1/4] 准备 staging: $pkgDir" -ForegroundColor Green

# robocopy /MIR + /XD 排除目录 + /XF 排除文件
$stageTarget = Join-Path $pkgDir '自动化取证'
New-Item -ItemType Directory -Force -Path $stageTarget | Out-Null

$excludeDirs = @(
    'cases',           # 所有比赛的工作目录（含敏感答案）
    'tools',           # 体积大，用脚本重装
    '.venv', '.venv-forensics',
    'node_modules', '__pycache__',
    '.git'             # 不带 git 历史
)
$excludeFiles = @(
    '*.E01','*.dd','*.vmdk','*.vhd',
    '*.pcap','*.pcapng',
    '*.7z','*.tar','*.img','*.vmem','*.raw',
    '.venv-path'
)

$args = @(
    $ProjRoot, $stageTarget,
    '/MIR', '/NFL','/NDL','/NJH','/NJS','/NC','/NS','/NP',
    '/XD') + $excludeDirs + @('/XF') + $excludeFiles

& robocopy @args | Out-Null
# robocopy exit codes 0-7 都是成功
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with $LASTEXITCODE" }

Write-Host "    [OK] 已 stage（排除 cases/tools/证据/压缩包/git）" -ForegroundColor DarkGreen

# -------------------------------------------------------------------
# 2. 建一个空的 cases/ 和 tools/ 目录（只留说明）
# -------------------------------------------------------------------
Write-Host "[2/4] 建骨架占位" -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "$stageTarget\cases" | Out-Null
Set-Content -Path "$stageTarget\cases\README.md" -Encoding UTF8 -Value @'
# cases/

本目录用于存放每场比赛。**不随分发包同步**——每人本地自己建。
拿到检材后，给 AI 说：
  @/SESSION_START.md 比赛叫 <名字>，检材在 <路径>
AI 会自动在此目录下建新比赛子目录。
'@

New-Item -ItemType Directory -Force -Path "$stageTarget\tools" | Out-Null
Set-Content -Path "$stageTarget\tools\README.md" -Encoding UTF8 -Value @'
# tools/

本目录用于存放 Zimmerman 套件等 Windows 取证工具。**不随分发包同步**。
跑 `scripts\bootstrap_new_machine.ps1` 会自动下载到这里。
'@

# -------------------------------------------------------------------
# 3. 可选：带上 Karpathy 指南
# -------------------------------------------------------------------
if ($IncludeKarpathy) {
    $karpSrc = Join-Path $ParentDir 'andrej-karpathy-skills-main'
    if (Test-Path $karpSrc) {
        Write-Host "[3/4] 带上 Karpathy 指南" -ForegroundColor Green
        Copy-Item -Recurse $karpSrc (Join-Path $pkgDir 'andrej-karpathy-skills-main')
        Write-Host "    [OK] 已包含" -ForegroundColor DarkGreen
    } else {
        Write-Host "[3/4] 未找到 Karpathy 指南源（$karpSrc），跳过" -ForegroundColor Yellow
    }
} else {
    Write-Host "[3/4] 跳过 Karpathy（用 -IncludeKarpathy 开启）" -ForegroundColor Gray
}

# -------------------------------------------------------------------
# 4. 写收件人 README + 打 zip
# -------------------------------------------------------------------
Write-Host "[4/4] 生成收件人 README + 压缩" -ForegroundColor Green

$readmeTo = Join-Path $pkgDir 'README_收件人必读.md'
Set-Content -Path $readmeTo -Encoding UTF8 -Value @"
# 收件人必读（解压后看这里）

> 打包时间：$ts  来自：$([Environment]::UserName)@$([Environment]::MachineName)

---

## 3 步上手

### 1. 把 \`自动化取证\` 文件夹挪到你的 E 盘

放到 **\`E:\项目\自动化取证\\\`** （路径最好一样，脚本默认是这个路径）。

### 2. 一键装环境

**前置**：已装 Windsurf + WSL2 Ubuntu。
```powershell
# 以普通 PowerShell 打开（不需要管理员）
cd E:\项目\自动化取证
powershell -ExecutionPolicy Bypass -File scripts\bootstrap_new_machine.ps1
```
大约 10-20 分钟装好 Zimmerman + WSL 取证工具。

### 3. 在 Windsurf 里打开

\`File > Open Folder\` → 选 \`E:\项目\自动化取证\\\`

新建对话，选一种模式：

**SOLO 模式（最快拿分）**：
\`\`\`
@SESSION_START.md SOLO 模式，比赛叫 <名字>，检材在 A:\
\`\`\`

**COOP 模式（triage 后做题）**：
\`\`\`
@SESSION_START.md COOP 模式，比赛叫 <名字>，检材在 A:\
\`\`\`

**TEAM 模式（三机 Git 协同）**：见 \`THREE_MACHINE_SOP.md\`，不是走压缩包方式，走 Git clone。

---

## Windsurf 规则会自动加载吗？

会。本项目用的是**项目级规则** \`.windsurf\rules\project-rules.md\`，Windsurf 一打开此文件夹就自动应用。**不依赖你的账号 memory**。

如果你习惯了自己账号的 Global Rules，项目级规则会与之叠加，不冲突。

---

## 有问题？

- 先让 AI 跑 \`/env-check\`
- 看 \`TRANSFER_GUIDE.md\` 常见坑列表
- 看 \`PLAYBOOK.md\` 找具体检材类型套路
"@

# 打 zip
$zipPath = Join-Path $OutDir "$pkgName.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Write-Host "    压缩中：$zipPath" -ForegroundColor Yellow
Compress-Archive -Path "$pkgDir\*" -DestinationPath $zipPath -CompressionLevel Optimal

$size = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  ✅ 打包完成" -ForegroundColor Cyan
Write-Host "  ZIP:   $zipPath  ($size MB)" -ForegroundColor Cyan
Write-Host "  Stage: $pkgDir  (可人工检查后删除)" -ForegroundColor Gray
Write-Host ""
Write-Host "  给队友发 ZIP 即可。解压后看里面的 README_收件人必读.md" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
