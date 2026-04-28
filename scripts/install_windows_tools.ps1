#Requires -Version 5.1
<#
Purpose : Download portable Windows forensics tools into ..\tools.
Origin  : 自动化取证 project bootstrap, 2026-04-24.
Idempotent : re-running will refresh Zimmerman tools and skip already-present archives.
#>

[CmdletBinding()]
param(
    [string]$ToolsDir = ''
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not $ToolsDir) {
    $ToolsDir = Join-Path $PSScriptRoot '..\tools'
}
New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
$ToolsDir = (Resolve-Path $ToolsDir).Path
Write-Host "[*] Tools dir: $ToolsDir" -ForegroundColor Cyan

function Download-File {
    param([string]$Url, [string]$Dest)
    if (Test-Path $Dest) {
        Write-Host "    - exists: $(Split-Path $Dest -Leaf)" -ForegroundColor DarkGray
        return
    }
    Write-Host "    - downloading $Url" -ForegroundColor Yellow
    & curl.exe -L --fail --silent --show-error -o $Dest $Url
    if ($LASTEXITCODE -ne 0) { throw "download failed: $Url" }
}

# -------------------------------------------------------------------
# 1. 7-Zip standalone console (7zr.exe) — fallback for .7z on Windows.
#    Zip archives go through PowerShell's Expand-Archive; everything
#    heavier is done in WSL (`p7zip-full`).
# -------------------------------------------------------------------
Write-Host "`n[1/3] 7-Zip (portable console)" -ForegroundColor Green
$sevenZipDir = Join-Path $ToolsDir '7zip'
New-Item -ItemType Directory -Force -Path $sevenZipDir | Out-Null
Download-File 'https://www.7-zip.org/a/7zr.exe' (Join-Path $sevenZipDir '7zr.exe')

# -------------------------------------------------------------------
# 2. Eric Zimmerman tools (via official bootstrapper)
# -------------------------------------------------------------------
Write-Host "`n[2/3] Eric Zimmerman tools (.NET 6 build)" -ForegroundColor Green
$ezDir = Join-Path $ToolsDir 'EZ'
New-Item -ItemType Directory -Force -Path $ezDir | Out-Null
$ezBoot = Join-Path $ezDir 'Get-ZimmermanTools.ps1'
if (-not (Test-Path $ezBoot)) {
    $ezZip = Join-Path $ezDir 'Get-ZimmermanTools.zip'
    Download-File 'https://f001.backblazeb2.com/file/EricZimmermanTools/Get-ZimmermanTools.zip' $ezZip
    Expand-Archive -Path $ezZip -DestinationPath $ezDir -Force
    Remove-Item $ezZip -Force
}
Push-Location $ezDir
try {
    # NetVersion 4 = .NET Framework (Windows 自带，零依赖). 9 需要安装 .NET 9 Runtime.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ezBoot -Dest $ezDir -NetVersion 4
} finally {
    Pop-Location
}

# -------------------------------------------------------------------
# 3. Summary
# -------------------------------------------------------------------
Write-Host "`n[3/3] Verifying key binaries" -ForegroundColor Green
$expected = @(
    'EZ\MFTECmd.exe',
    'EZ\EvtxeCmd\EvtxECmd.exe',
    'EZ\PECmd.exe',
    'EZ\RECmd\RECmd.exe',
    'EZ\LECmd.exe',
    'EZ\JLECmd.exe',
    'EZ\SBECmd.exe',
    'EZ\AmcacheParser.exe',
    '7zip\7zr.exe'
)
$missing = @()
foreach ($rel in $expected) {
    $p = Join-Path $ToolsDir $rel
    if (Test-Path $p) {
        Write-Host "    [OK] $rel" -ForegroundColor DarkGreen
    } else {
        Write-Host "    [--] $rel" -ForegroundColor Red
        $missing += $rel
    }
}

if ($missing.Count -eq 0) {
    Write-Host "`nAll Windows tools ready." -ForegroundColor Cyan
} else {
    Write-Host "`n$($missing.Count) item(s) missing, re-run the script." -ForegroundColor Yellow
}
