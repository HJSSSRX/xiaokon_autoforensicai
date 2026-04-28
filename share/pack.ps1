#Requires -Version 5.1
# Purpose: Pack share/ into forensics-agent-starter.zip
# Usage:   .\share\pack.ps1

$ErrorActionPreference = 'Stop'
$ProjRoot = Split-Path $PSScriptRoot -Parent
$ShareDir = $PSScriptRoot
$SkeletonDir = Join-Path $ShareDir 'skeleton'
$RefCaseDir = Join-Path $ShareDir 'reference_case'

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  forensics-agent-starter packer' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

# --- 1. Populate skeleton/ ---
Write-Host '[1/4] Populate skeleton/' -ForegroundColor Green

if (Test-Path $SkeletonDir) { Remove-Item -Recurse -Force $SkeletonDir }
New-Item -ItemType Directory -Path $SkeletonDir -Force | Out-Null

# AI_BRAIN
$srcBrain = Join-Path $ProjRoot 'AI_BRAIN'
$dstBrain = Join-Path $SkeletonDir 'AI_BRAIN'
Copy-Item -Recurse $srcBrain $dstBrain
Get-ChildItem (Join-Path $dstBrain 'session_handoff*.md') -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Name -match '\d{4}-\d{2}-\d{2}') { Remove-Item $_.FullName }
}

# knowledge
$src = Join-Path $ProjRoot 'knowledge'
if (Test-Path $src) { Copy-Item -Recurse $src (Join-Path $SkeletonDir 'knowledge') }

# modes
$src = Join-Path $ProjRoot 'modes'
if (Test-Path $src) { Copy-Item -Recurse $src (Join-Path $SkeletonDir 'modes') }

# roles
$src = Join-Path $ProjRoot 'roles'
if (Test-Path $src) { Copy-Item -Recurse $src (Join-Path $SkeletonDir 'roles') }

# .windsurf
$src = Join-Path $ProjRoot '.windsurf'
if (Test-Path $src) { Copy-Item -Recurse $src (Join-Path $SkeletonDir '.windsurf') }

# Root-level docs
$rootDocs = @('WP_FORMAT.md','KARPATHY_GUIDELINES.md','SESSION_START.md','PLAYBOOK.md','README.md','TOOLS.md','.gitignore')
foreach ($doc in $rootDocs) {
    $src = Join-Path $ProjRoot $doc
    if (Test-Path $src) { Copy-Item $src (Join-Path $SkeletonDir $doc) }
}

# Case template
$caseTemplate = Join-Path $SkeletonDir 'cases\_template'
New-Item -ItemType Directory -Path (Join-Path $caseTemplate 'wp_batches') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $caseTemplate 'artifacts') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $caseTemplate 'evidence') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $caseTemplate 'notes') -Force | Out-Null
Set-Content -Path (Join-Path $caseTemplate 'README.md') -Value '# New case template' -Encoding ASCII

# Scripts (generic only)
$scriptDir = Join-Path $SkeletonDir 'scripts'
New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
$genericScripts = @('env_healthcheck.ps1','env_healthcheck.sh','install_wsl_tools.sh','install_windows_tools.ps1','bootstrap_new_machine.ps1','ask_advisor.py','README.md')
foreach ($s in $genericScripts) {
    $src = Join-Path $ProjRoot "scripts\$s"
    if (Test-Path $src) { Copy-Item $src (Join-Path $scriptDir $s) }
}

Write-Host '  [OK] skeleton/ populated' -ForegroundColor Green

# --- 2. Populate reference_case/ ---
Write-Host ''
Write-Host '[2/4] Populate reference_case/' -ForegroundColor Green

$qSrc = Join-Path $ProjRoot 'cases\2026FIC电子取证\questions.md'
if (Test-Path $qSrc) { Copy-Item $qSrc (Join-Path $RefCaseDir 'questions.md') }

$wpSrc = Join-Path $ProjRoot 'cases\2026FIC电子取证\wp_batches'
$wpDst = Join-Path $RefCaseDir 'wp_batches'
if (Test-Path $wpSrc) {
    if (Test-Path $wpDst) { Remove-Item -Recurse -Force $wpDst }
    Copy-Item -Recurse $wpSrc $wpDst
}

Write-Host '  [OK] reference_case/ populated' -ForegroundColor Green

# --- 3. Create zip ---
Write-Host ''
Write-Host '[3/4] Create zip' -ForegroundColor Green
$zipPath = Join-Path $ProjRoot 'forensics-agent-starter.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath }

Add-Type -Assembly 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::CreateFromDirectory($ShareDir, $zipPath)

$sizeBytes = (Get-Item $zipPath).Length
$sizeMB = [math]::Round($sizeBytes / 1MB, 2)
Write-Host ('  [OK] {0} ({1} MB)' -f $zipPath, $sizeMB) -ForegroundColor Green

# --- 4. Summary ---
Write-Host ''
Write-Host '[4/4] Done' -ForegroundColor Green

$fileCount = (Get-ChildItem -Recurse $ShareDir -File).Count
Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  forensics-agent-starter packed' -ForegroundColor Cyan
Write-Host ''
Write-Host ('  Files: {0}' -f $fileCount)
Write-Host ('  ZIP:   {0}' -f $zipPath)
Write-Host ''
Write-Host '  Next: send zip, unzip, run install/, read QUICKSTART_AGENT.md'
Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
