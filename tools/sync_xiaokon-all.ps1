<#
.SYNOPSIS
    One-shot sync between local master and HJSSSRX/xiaokon-all main.

.DESCRIPTION
    Workflow:
        1. Network pre-check (calls check_net.ps1; auto-enables schannel if hijacked)
        2. Working tree clean + branch=master assertion
        3. fetch xiaokon-all
        4. If remote ahead -> merge --no-ff (auto-abort on conflict)
        5. push xiaokon-all master:main (unless -NoPush)

.PARAMETER NoPush
    Pull side only, do not push.

.PARAMETER DryRun
    Print what would happen, do not actually merge or push.

.NOTES
    Eats own dogfood: this is the canonical way to push to xiaokon-all from now on.
#>
[CmdletBinding()]
param(
    [switch]$NoPush,
    [switch]$DryRun
)

$repo = Split-Path $PSScriptRoot -Parent

function Step {
    param([string]$Tag, [string]$Msg)
    Write-Host ''
    Write-Host "== [$Tag] $Msg ==" -ForegroundColor Cyan
}

function Die {
    param([string]$Msg, [int]$Code = 1)
    Write-Host "[sync][FAIL] $Msg" -ForegroundColor Red
    exit $Code
}

# 1. Network pre-check
Step 1 'NETWORK CHECK'
& "$repo\tools\check_net.ps1"
$netCode = $LASTEXITCODE
$sslOpt = @()
switch ($netCode) {
    0 { Write-Host '  -> OK' -ForegroundColor Green }
    1 {
        Write-Host '  -> hijacked, auto-enabling http.sslBackend=schannel' -ForegroundColor Yellow
        $sslOpt = @('-c', 'http.sslBackend=schannel')
    }
    default { Die "DNS unreachable (check_net exit=$netCode)" }
}

# 2. Working tree + branch
Step 2 'WORKING TREE'
$dirty = git -C $repo status --porcelain
if ($dirty) {
    Write-Host '  uncommitted changes:' -ForegroundColor Red
    Write-Host $dirty
    Die 'commit or stash first'
}
$branch = git -C $repo rev-parse --abbrev-ref HEAD
if ($branch -ne 'master') {
    Die "not on master branch (actual: $branch)"
}
Write-Host '  -> clean, branch=master' -ForegroundColor Green

# 3. Fetch
Step 3 'FETCH xiaokon-all'
git -C $repo @sslOpt fetch xiaokon-all
if ($LASTEXITCODE) { Die "fetch failed" $LASTEXITCODE }

# 4. Merge
Step 4 'MERGE'
$ahead = [int](git -C $repo rev-list --count HEAD..xiaokon-all/main)
$behind = [int](git -C $repo rev-list --count xiaokon-all/main..HEAD)
Write-Host "  -> remote ahead $ahead / local ahead $behind"
if ($ahead -gt 0) {
    Write-Host '  -> incoming commits:'
    git -C $repo log --oneline HEAD..xiaokon-all/main
    if ($DryRun) {
        Write-Host '  -> [DryRun] skipping merge' -ForegroundColor Yellow
    } else {
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
        git -C $repo merge --no-ff xiaokon-all/main -m "Merge xiaokon-all/main (auto-sync $stamp)"
        if ($LASTEXITCODE) {
            Write-Host '  -> merge had conflicts, aborting...' -ForegroundColor Red
            git -C $repo merge --abort
            Die 'merge conflict -- resolve manually then re-run'
        }
        Write-Host '  -> merged' -ForegroundColor Green
    }
} else {
    Write-Host '  -> already up-to-date' -ForegroundColor Green
}

# 5. Push
Step 5 'PUSH'
if ($NoPush) {
    Write-Host '  -> skipped (-NoPush)' -ForegroundColor Yellow
} elseif ($DryRun) {
    Write-Host '  -> [DryRun] would: git push xiaokon-all master:main' -ForegroundColor Yellow
} else {
    git -C $repo @sslOpt push xiaokon-all master:main
    if ($LASTEXITCODE) { Die "push failed" $LASTEXITCODE }
    Write-Host '  -> pushed' -ForegroundColor Green
}

Step 'DONE' 'sync complete'
