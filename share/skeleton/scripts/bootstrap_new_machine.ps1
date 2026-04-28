#Requires -Version 5.1
<#
Purpose : 在新 Win11 电脑上一键部署自动化取证工作环境。
Origin  : 自动化取证 project, 2026-04-24.

使用方式：
    powershell -ExecutionPolicy Bypass -File scripts\bootstrap_new_machine.ps1

前置条件：
    - Windows 11
    - 已安装 WSL Ubuntu（如未装，先以管理员跑 `wsl --install -d Ubuntu`）
    - 已安装 Windsurf 并登录账号
#>

[CmdletBinding()]
param(
    [switch]$SkipWindows,
    [switch]$SkipWSL
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ProjRoot = Split-Path $PSScriptRoot -Parent
Write-Host "[*] Project root: $ProjRoot" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------
# 0. 前置检查
# -----------------------------------------------------------------
Write-Host "[0/4] 前置检查" -ForegroundColor Green

# WSL 是否可用
$wslOk = $true
try { wsl -l -q | Out-Null } catch { $wslOk = $false }
if (-not $wslOk) {
    Write-Host "    [!!] WSL 未安装。请以管理员运行：wsl --install -d Ubuntu，重启后再跑本脚本。" -ForegroundColor Red
    exit 1
}
Write-Host "    [OK] WSL 可用" -ForegroundColor DarkGreen

# Karpathy 指南是否存在（不强制，但会警告）
$karpathyPath = Join-Path (Split-Path $ProjRoot -Parent) 'andrej-karpathy-skills-main\CLAUDE.md'
if (Test-Path $karpathyPath) {
    Write-Host "    [OK] 发现 Karpathy 指南：$karpathyPath" -ForegroundColor DarkGreen
} else {
    Write-Host "    [--] 未发现 Karpathy 指南 (E:\项目\andrej-karpathy-skills-main\CLAUDE.md)" -ForegroundColor Yellow
    Write-Host "         建议从 https://github.com/forrestchang/andrej-karpathy-skills 拉取到 E:\项目\" -ForegroundColor Yellow
}

# -----------------------------------------------------------------
# 1. Windows 端工具
# -----------------------------------------------------------------
if (-not $SkipWindows) {
    Write-Host ""
    Write-Host "[1/4] 安装 Windows 取证工具（Zimmerman + 7zr）" -ForegroundColor Green
    & (Join-Path $PSScriptRoot 'install_windows_tools.ps1')
} else {
    Write-Host "[1/4] SKIP Windows tools (--SkipWindows)" -ForegroundColor Gray
}

# -----------------------------------------------------------------
# 2. WSL 端工具
# -----------------------------------------------------------------
if (-not $SkipWSL) {
    Write-Host ""
    Write-Host "[2/4] 安装 WSL 取证工具（sleuthkit / volatility3 / aleapp / ...）" -ForegroundColor Green
    # WSL 路径转换
    $wslScript = '/mnt/' + ($ProjRoot -replace ':','' -replace '\\','/' -replace '^([A-Z])',{$_.Value.ToLower()})
    $wslScript = $wslScript + '/scripts/install_wsl_tools.sh'
    Write-Host "    - 运行：bash $wslScript" -ForegroundColor Yellow
    wsl -e bash -lc "bash '$wslScript'"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [!!] WSL 工具安装返回非零状态。检查 WSL 内的 apt/网络。" -ForegroundColor Red
    }
} else {
    Write-Host "[2/4] SKIP WSL tools (--SkipWSL)" -ForegroundColor Gray
}

# -----------------------------------------------------------------
# 3. 确保关键文档存在
# -----------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] 关键文档完整性检查" -ForegroundColor Green
$required = @(
    'SESSION_START.md',
    'PLAYBOOK.md',
    'TOOLS.md',
    'TRANSFER_GUIDE.md',
    'THREE_MACHINE_SOP.md',
    'WP_FORMAT.md',
    'KARPATHY_GUIDELINES.md',
    'scripts\install_wsl_tools.sh',
    'scripts\install_windows_tools.ps1',
    'scripts\env_healthcheck.ps1',
    'scripts\env_healthcheck.sh'
)
$miss = @()
foreach ($rel in $required) {
    $full = Join-Path $ProjRoot $rel
    if (Test-Path $full) {
        Write-Host "    [OK] $rel" -ForegroundColor DarkGreen
    } else {
        Write-Host "    [--] 缺失: $rel" -ForegroundColor Red
        $miss += $rel
    }
}

# -----------------------------------------------------------------
# 4. 健康检查
# -----------------------------------------------------------------
Write-Host ""
Write-Host "[4/4] 环境健康检查" -ForegroundColor Green
if (Test-Path (Join-Path $PSScriptRoot 'env_healthcheck.ps1')) {
    & (Join-Path $PSScriptRoot 'env_healthcheck.ps1')
} else {
    Write-Host "    [--] env_healthcheck.ps1 未找到（部署未完整）" -ForegroundColor Yellow
}

# -----------------------------------------------------------------
# 总结
# -----------------------------------------------------------------
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
if ($miss.Count -eq 0) {
    Write-Host "  ✅ 部署完成。打开 Windsurf，对话说 '@SESSION_START.md 接着干'。" -ForegroundColor Cyan
} else {
    Write-Host "  ⚠ 部署完成但 $($miss.Count) 个文档缺失，需手动补齐。" -ForegroundColor Yellow
}
Write-Host "====================================================" -ForegroundColor Cyan
