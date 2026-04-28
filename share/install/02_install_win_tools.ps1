#Requires -Version 5.1
<#
.SYNOPSIS
    Install Windows-side tools for forensics-agent-starter.
.DESCRIPTION
    Installs 7zip via winget/choco, and provides guidance for manual tools.
#>

$ErrorActionPreference = "Continue"
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Windows 工具安装" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ---- 7zip ----
Write-Host "[1/3] 7-Zip" -ForegroundColor White
if (Get-Command "7z" -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] 7z 已安装" -ForegroundColor Green
} else {
    Write-Host "  安装 7-Zip..." -ForegroundColor Yellow
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        winget install --id 7zip.7zip --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command "choco" -ErrorAction SilentlyContinue) {
        choco install 7zip -y
    } else {
        Write-Host "  [WARN] 请手动安装 7-Zip: https://www.7-zip.org/" -ForegroundColor Yellow
    }
}

# ---- Git ----
Write-Host "`n[2/3] Git" -ForegroundColor White
if (Get-Command "git" -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] git 已安装: $(git --version)" -ForegroundColor Green
} else {
    Write-Host "  安装 Git..." -ForegroundColor Yellow
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        winget install --id Git.Git --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command "choco" -ErrorAction SilentlyContinue) {
        choco install git -y
    } else {
        Write-Host "  [WARN] 请手动安装 Git: https://git-scm.com/" -ForegroundColor Yellow
    }
}

# ---- Manual tools guidance ----
Write-Host "`n[3/3] 手动安装工具（推荐）" -ForegroundColor White
Write-Host @"

  以下工具建议手动下载安装（取证比赛常用）：

  ┌─────────────────────────┬─────────────────────────────────────────────┐
  │ 工具                    │ 下载地址                                     │
  ├─────────────────────────┼─────────────────────────────────────────────┤
  │ Arsenal Image Mounter   │ https://arsenalrecon.com/downloads           │
  │ FTK Imager              │ https://www.exterro.com/ftk-imager           │
  │ Eric Zimmerman Tools    │ https://ericzimmerman.github.io/#!index.md   │
  │   (MFTECmd, EvtxECmd)   │                                             │
  │ Autopsy                 │ https://www.autopsy.com/download/            │
  │ Wireshark               │ https://www.wireshark.org/download.html      │
  └─────────────────────────┴─────────────────────────────────────────────┘

  下载后放到项目的 tools/ 目录下即可。

"@ -ForegroundColor DarkGray

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows 工具安装完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
