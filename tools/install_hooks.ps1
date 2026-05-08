<#
.SYNOPSIS
    Install repository-tracked git hooks by setting core.hooksPath = .githooks.

.DESCRIPTION
    Hooks under .git/hooks/ are not tracked. To distribute hooks via the repo,
    we keep them under .githooks/ (tracked) and point each clone's
    core.hooksPath at it. This script does that, idempotently.

    Run once per fresh clone.

.NOTES
    On Windows the shell scripts work because Git for Windows ships with sh.exe.
    No chmod needed.
#>

$repo = Split-Path $PSScriptRoot -Parent
$hookDir = Join-Path $repo '.githooks'

if (-not (Test-Path $hookDir)) {
    Write-Host "[install_hooks][FAIL] missing $hookDir" -ForegroundColor Red
    exit 1
}

git -C $repo config core.hooksPath '.githooks'
$set = git -C $repo config --get core.hooksPath
Write-Host "[install_hooks][OK] core.hooksPath = $set" -ForegroundColor Green

Write-Host "[install_hooks] hooks under $hookDir :"
Get-ChildItem $hookDir -File | ForEach-Object {
    Write-Host "  - $($_.Name)"
}
