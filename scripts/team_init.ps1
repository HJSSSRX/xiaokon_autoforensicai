#Requires -Version 5.1
<#
Purpose : 新机加入团队一键初始化：clone 团队仓 + 切板块分支 + 本地检材盘校验。
Usage   : powershell -ExecutionPolicy Bypass -File scripts\team_init.ps1 `
              -RepoUrl 'git@gitee.com:xxx/team-forensics.git' `
              -Role 'phone'   # 或 'pc' / 'server'
              [-TeamDir 'E:\项目\团队协作']
              [-CaseName '2026FIC']
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RepoUrl,
    [Parameter(Mandatory=$true)][ValidateSet('phone','pc','server')][string]$Role,
    [string]$TeamDir = 'E:\项目\团队协作',
    [string]$CaseName = ''
)

$ErrorActionPreference = 'Stop'
Write-Host "=== TEAM 模式初始化 · $Role 板块 ===" -ForegroundColor Cyan

# -----------------------------------------------------
# 1. git 可用性
# -----------------------------------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[!!] 找不到 git，请先安装 Git for Windows" -ForegroundColor Red
    exit 1
}

# -----------------------------------------------------
# 2. clone or pull
# -----------------------------------------------------
New-Item -ItemType Directory -Force -Path $TeamDir | Out-Null
Set-Location $TeamDir
$repoName = Split-Path -Leaf ($RepoUrl -replace '\.git$','')
$repoPath = Join-Path $TeamDir $repoName

if (Test-Path $repoPath\.git) {
    Write-Host "[*] 仓已存在，更新中：$repoPath" -ForegroundColor Yellow
    Set-Location $repoPath
    git fetch --all
    git pull --rebase origin main
} else {
    Write-Host "[*] 首次克隆：$RepoUrl -> $repoPath" -ForegroundColor Yellow
    git clone $RepoUrl $repoPath
    Set-Location $repoPath
}

# -----------------------------------------------------
# 3. 切到本机板块分支
# -----------------------------------------------------
$branch = "$Role-work"
$exists = git branch --list $branch
if (-not $exists) {
    git checkout -b $branch
    Write-Host "[*] 新建分支：$branch" -ForegroundColor Green
} else {
    git checkout $branch
    git merge --no-edit main
    Write-Host "[*] 切到分支：$branch (已 merge main)" -ForegroundColor Green
}

# -----------------------------------------------------
# 4. 本机 Role 身份卡检查
# -----------------------------------------------------
$roleFile = Join-Path $repoPath "roles\ROLE_$Role.md"
if (Test-Path $roleFile) {
    Write-Host "[OK] 身份卡：$roleFile" -ForegroundColor DarkGreen
} else {
    Write-Host "[!!] 身份卡缺失：$roleFile — 确认 repo 内容完整" -ForegroundColor Red
}

# -----------------------------------------------------
# 5. 比赛目录准备
# -----------------------------------------------------
if ($CaseName) {
    $caseDir = Join-Path $repoPath "shared\cases\$CaseName"
    if (-not (Test-Path $caseDir)) {
        $tmpl = Join-Path $repoPath "shared\cases\_template"
        if (Test-Path $tmpl) {
            Copy-Item -Recurse $tmpl $caseDir
            Write-Host "[*] 已从 _template 创建：$caseDir" -ForegroundColor Green
            Write-Host "    (如果你不是队长，请让队长 commit 并 push 后再跑本步)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[OK] 比赛目录已存在：$caseDir" -ForegroundColor DarkGreen
    }
}

# -----------------------------------------------------
# 6. 指引用户
# -----------------------------------------------------
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  ✅ TEAM 初始化完成" -ForegroundColor Cyan
Write-Host "  仓位置: $repoPath" -ForegroundColor Cyan
Write-Host "  本机板块: $Role  分支: $branch" -ForegroundColor Cyan
Write-Host ""
Write-Host "  下一步：用 Windsurf 打开 $repoPath" -ForegroundColor Yellow
Write-Host "  对话框贴：" -ForegroundColor Yellow
Write-Host "    @SESSION_START.md @roles/ROLE_$Role.md TEAM 模式，本机 $Role" -ForegroundColor White
Write-Host "====================================================" -ForegroundColor Cyan
