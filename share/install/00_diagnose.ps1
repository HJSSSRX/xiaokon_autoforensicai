#Requires -Version 5.1
<#
.SYNOPSIS
    Environment diagnostic for forensics-agent-starter.
    Run this FIRST before installing anything.
.DESCRIPTION
    Checks: WSL availability, Python version, disk space, proxy, installed tools.
    Outputs a report with [OK] / [WARN] / [FAIL] indicators.
#>

param(
    [string]$ProxyUrl = ""  # optional: http://127.0.0.1:7897
)

$ErrorActionPreference = "Continue"
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  forensics-agent-starter 环境诊断" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$ok = 0; $warn = 0; $fail = 0

function Report($level, $msg) {
    switch ($level) {
        "OK"   { Write-Host "  [OK]   $msg" -ForegroundColor Green;  $script:ok++ }
        "WARN" { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:warn++ }
        "FAIL" { Write-Host "  [FAIL] $msg" -ForegroundColor Red;    $script:fail++ }
    }
}

# ---- 1. OS ----
Write-Host "[1/6] 操作系统" -ForegroundColor White
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$build = [System.Environment]::OSVersion.Version.Build
Report "OK" "$os (Build $build)"
if ($build -lt 19041) { Report "WARN" "建议 Windows 10 2004+ 或 Windows 11 以获得 WSL2 支持" }

# ---- 2. WSL ----
Write-Host "`n[2/6] WSL" -ForegroundColor White
try {
    $wslList = wsl --list --verbose 2>&1
    if ($LASTEXITCODE -eq 0 -and $wslList -match "Running|Stopped") {
        Report "OK" "WSL 已安装"
        $wslList | ForEach-Object { Write-Host "         $_" -ForegroundColor DarkGray }
        # Check WSL version
        $ver = wsl -e bash -lc "cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'\"' -f2" 2>$null
        if ($ver) { Report "OK" "WSL distro: $ver" } else { Report "WARN" "无法读取 WSL distro 信息" }
    } else {
        Report "FAIL" "WSL 未安装或未运行。请先安装: wsl --install"
    }
} catch {
    Report "FAIL" "WSL 命令不可用: $_"
}

# ---- 3. Python ----
Write-Host "`n[3/6] Python (WSL)" -ForegroundColor White
try {
    $pyVer = wsl -e bash -lc "python3 --version 2>/dev/null" 2>$null
    if ($pyVer -match "Python 3\.(\d+)") {
        $minor = [int]$Matches[1]
        if ($minor -ge 10) { Report "OK" "$pyVer" }
        else { Report "WARN" "$pyVer (建议 3.10+)" }
    } else {
        Report "FAIL" "Python3 未安装 (WSL)"
    }
} catch {
    Report "FAIL" "无法检查 Python: $_"
}

# ---- 4. 磁盘空间 ----
Write-Host "`n[4/6] 磁盘空间" -ForegroundColor White
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
    $freeGB = [math]::Round($_.Free / 1GB, 1)
    $name = $_.Root
    if ($freeGB -lt 10) { Report "WARN" "$name 剩余 ${freeGB}GB (建议 >10GB)" }
    else { Report "OK" "$name 剩余 ${freeGB}GB" }
}

# ---- 5. 代理 / 网络 ----
Write-Host "`n[5/6] 网络" -ForegroundColor White
try {
    $r = Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Report "OK" "外网可达 (baidu.com)"
} catch {
    Report "WARN" "外网不可达（离线环境或需代理）"
}
if ($ProxyUrl) {
    try {
        $r = Invoke-WebRequest -Uri "https://www.google.com" -Proxy $ProxyUrl -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Report "OK" "代理可用: $ProxyUrl"
    } catch {
        Report "WARN" "代理不可达: $ProxyUrl"
    }
}

# ---- 6. 已安装的关键工具 ----
Write-Host "`n[6/6] 已安装工具 (WSL)" -ForegroundColor White
$tools = @(
    @("sqlite3",    "数据库查询"),
    @("strings",    "字符串提取"),
    @("grep",       "文本搜索"),
    @("find",       "文件查找"),
    @("file",       "文件类型识别"),
    @("xxd",        "hex dump"),
    @("openssl",    "密码学工具"),
    @("7z",         "压缩解压"),
    @("exiftool",   "元数据提取"),
    @("rg",         "ripgrep"),
    @("jq",         "JSON处理"),
    @("r2",         "radare2 逆向"),
    @("jadx",       "APK反编译"),
    @("fls",        "sleuthkit"),
    @("ewfmount",   "E01挂载"),
    @("tshark",     "网络包分析"),
    @("pip3",       "Python包管理")
)

foreach ($t in $tools) {
    $cmd = $t[0]; $desc = $t[1]
    $r = wsl -e bash -lc "command -v $cmd >/dev/null 2>&1 && echo OK || echo MISS" 2>$null
    if ($r -match "OK") { Report "OK" "$cmd ($desc)" }
    else { Report "WARN" "$cmd 未安装 ($desc)" }
}

# Python packages
$pyPkgs = @("pycryptodome", "sqlcipher3", "openpyxl")
foreach ($pkg in $pyPkgs) {
    $r = wsl -e bash -lc "python3 -c 'import $($pkg.Replace('-','_').Replace('3',''))' 2>/dev/null && echo OK || echo MISS" 2>$null
    if ($r -match "OK") { Report "OK" "pip: $pkg" }
    else { Report "WARN" "pip: $pkg 未安装" }
}

# ---- Summary ----
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  OK: $ok  |  WARN: $warn  |  FAIL: $fail" -ForegroundColor $(
    if ($fail -gt 0) { "Red" } elseif ($warn -gt 0) { "Yellow" } else { "Green" }
)
Write-Host "========================================" -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host "`n→ 有 FAIL 项，请先解决再继续。" -ForegroundColor Red
    Write-Host "  WSL 安装: wsl --install" -ForegroundColor Yellow
}
if ($warn -gt 0) {
    Write-Host "`n→ 有 WARN 项，运行安装脚本修复:" -ForegroundColor Yellow
    Write-Host "  WSL 工具: wsl bash share/install/01_install_wsl_tools.sh" -ForegroundColor Yellow
    Write-Host "  Win 工具: .\share\install\02_install_win_tools.ps1" -ForegroundColor Yellow
}
if ($fail -eq 0 -and $warn -eq 0) {
    Write-Host "`n→ 环境就绪！可以开始使用。" -ForegroundColor Green
}
