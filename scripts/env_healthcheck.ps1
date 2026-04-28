#Requires -Version 5.1
<#
Purpose : 30 秒内确认当前机器能干活：Windows 工具 + WSL 工具 + venv 都在。
使用    : 每次开新 session、或怀疑环境坏了时跑一次。
#>

$ProjRoot = Split-Path $PSScriptRoot -Parent
Write-Host "=== 自动化取证 · 环境健康检查 ===" -ForegroundColor Cyan
Write-Host "项目根: $ProjRoot"
Write-Host ""

$ok = 0; $fail = 0
function Check-File($path, $label) {
    if (Test-Path $path) {
        Write-Host "  [OK] $label" -ForegroundColor DarkGreen; $script:ok++
    } else {
        Write-Host "  [--] MISS: $label ($path)" -ForegroundColor Red; $script:fail++
    }
}
function Check-WslCmd($cmd, $label) {
    $r = wsl -e bash -lc "command -v $cmd >/dev/null 2>&1 && echo OK || echo MISS" 2>$null
    if ($r -match 'OK') {
        Write-Host "  [OK] WSL: $label" -ForegroundColor DarkGreen; $script:ok++
    } else {
        Write-Host "  [--] WSL: $label 不存在" -ForegroundColor Red; $script:fail++
    }
}

Write-Host "[1] Windows 工具" -ForegroundColor Green
Check-File (Join-Path $ProjRoot 'tools\EZ\MFTECmd.exe') 'MFTECmd.exe'
Check-File (Join-Path $ProjRoot 'tools\EZ\EvtxeCmd\EvtxECmd.exe') 'EvtxECmd.exe'
Check-File (Join-Path $ProjRoot 'tools\EZ\RECmd\RECmd.exe') 'RECmd.exe'
Check-File (Join-Path $ProjRoot 'tools\EZ\PECmd.exe') 'PECmd.exe'
Check-File (Join-Path $ProjRoot 'tools\7zip\7zr.exe') '7zr.exe'

Write-Host ""
Write-Host "[2] WSL 工具" -ForegroundColor Green
Check-WslCmd 'fls' 'sleuthkit(fls)'
Check-WslCmd 'mmls' 'sleuthkit(mmls)'
Check-WslCmd 'ewfmount' 'ewf-tools'
Check-WslCmd 'tshark' 'tshark'
Check-WslCmd 'sqlite3' 'sqlite3'
Check-WslCmd 'rg' 'ripgrep'
Check-WslCmd 'jq' 'jq'
Check-WslCmd '7z' 'p7zip'

Write-Host ""
Write-Host "[3] Python 取证包（venv 优先，系统 pip 兜底）" -ForegroundColor Green
$venvOk = wsl -e bash -lc 'test -f $HOME/.venv-forensics/bin/activate && echo OK || echo MISS' 2>$null
if ($venvOk -match 'OK') {
    Write-Host "  [OK] venv @ ~/.venv-forensics" -ForegroundColor DarkGreen; $ok++
    $aleOk = wsl -e bash -lc 'source $HOME/.venv-forensics/bin/activate; command -v aleapp >/dev/null && echo OK || echo MISS' 2>$null
    $volOk = wsl -e bash -lc 'source $HOME/.venv-forensics/bin/activate; command -v vol    >/dev/null && echo OK || echo MISS' 2>$null
} else {
    Write-Host "  [--] 无 venv（项目说明允许用系统 pip，下面直接检测 CLI）" -ForegroundColor Yellow
    $aleOk = wsl -e bash -lc 'command -v aleapp >/dev/null && echo OK || echo MISS' 2>$null
    $volOk = wsl -e bash -lc 'command -v vol >/dev/null && echo OK || echo MISS' 2>$null
}
if ($aleOk -match 'OK') { Write-Host "  [OK] aleapp" -ForegroundColor DarkGreen; $ok++ } else { Write-Host "  [--] aleapp" -ForegroundColor Red; $fail++ }
if ($volOk -match 'OK') { Write-Host "  [OK] volatility3 (vol)" -ForegroundColor DarkGreen; $ok++ } else { Write-Host "  [--] volatility3" -ForegroundColor Red; $fail++ }

Write-Host ""
Write-Host "[4] 项目关键文档" -ForegroundColor Green
Check-File (Join-Path $ProjRoot 'SESSION_START.md') 'SESSION_START.md'
Check-File (Join-Path $ProjRoot 'PLAYBOOK.md') 'PLAYBOOK.md'
Check-File (Join-Path $ProjRoot 'WP_FORMAT.md') 'WP_FORMAT.md'
Check-File (Join-Path $ProjRoot 'THREE_MACHINE_SOP.md') 'THREE_MACHINE_SOP.md'
Check-File (Join-Path $ProjRoot 'KARPATHY_GUIDELINES.md') 'KARPATHY_GUIDELINES.md'

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  PASS: $ok   FAIL: $fail" -ForegroundColor $(if($fail -eq 0){'Green'}else{'Yellow'})
Write-Host "=================================================" -ForegroundColor Cyan
if ($fail -gt 0) {
    Write-Host "→ 跑 scripts\bootstrap_new_machine.ps1 修复" -ForegroundColor Yellow
}
