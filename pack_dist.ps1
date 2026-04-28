#Requires -Version 5.1
<#
.SYNOPSIS
  Pack ForensicAI (小空自己动) into a clean distribution zip.
  The dist contains architecture skeleton but NO training data.
  Training data is downloaded separately via bootstrap.ps1.

.USAGE
  .\pack_dist.ps1
  # Output: forensicai-starter.zip in project root
#>

$ErrorActionPreference = 'Stop'
$ProjRoot  = $PSScriptRoot
$DistDir   = Join-Path $ProjRoot '_dist'
$ZipName   = 'forensicai-starter.zip'
$ZipPath   = Join-Path $ProjRoot $ZipName

Write-Host ''
Write-Host '================================================' -ForegroundColor Cyan
Write-Host '  ForensicAI Dist Packer  (skeleton, no data)'    -ForegroundColor Cyan
Write-Host '================================================' -ForegroundColor Cyan

# --- Clean previous build ---
if (Test-Path $DistDir)  { Remove-Item -Recurse -Force $DistDir }
if (Test-Path $ZipPath)  { Remove-Item -Force $ZipPath }
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null

# === Helper: copy if exists ===
function Copy-IfExists($src, $dst, [switch]$Recurse) {
    if (Test-Path $src) {
        if ($Recurse) { Copy-Item -Recurse $src $dst }
        else          { Copy-Item $src $dst }
    } else {
        Write-Host "  [SKIP] $src not found" -ForegroundColor Yellow
    }
}

# ===============================================================
# 1. Root-level docs (architecture, not data)
# ===============================================================
Write-Host '[1/7] Root docs' -ForegroundColor Green
$rootDocs = @(
    'AGENTS.md', 'CLAUDE.md', '.cursorrules',
    'README.md', 'CHANGELOG.md',
    'SESSION_START.md', 'PLAYBOOK.md', 'WP_FORMAT.md',
    'KARPATHY_GUIDELINES.md', 'TOOLS.md',
    '.gitignore'
)
foreach ($doc in $rootDocs) {
    Copy-IfExists (Join-Path $ProjRoot $doc) (Join-Path $DistDir $doc)
}

# ===============================================================
# 2. AI_BRAIN (persona + contract + tool list, NO solved_patterns data)
# ===============================================================
Write-Host '[2/7] AI_BRAIN (skeleton)' -ForegroundColor Green
$brainDst = Join-Path $DistDir 'AI_BRAIN'
New-Item -ItemType Directory -Path $brainDst -Force | Out-Null

foreach ($f in @('README.md','persona.md','output_contract.md','tool_inventory.md')) {
    Copy-IfExists (Join-Path $ProjRoot "AI_BRAIN\$f") (Join-Path $brainDst $f)
}
# solved_patterns: only README + template, not actual patterns
$spDst = Join-Path $brainDst 'solved_patterns'
New-Item -ItemType Directory -Path $spDst -Force | Out-Null
Set-Content (Join-Path $spDst '.gitkeep') '' -Encoding ASCII
Copy-IfExists (Join-Path $ProjRoot 'AI_BRAIN\solved_patterns\README.md') (Join-Path $spDst 'README.md')
Copy-IfExists (Join-Path $ProjRoot 'AI_BRAIN\solved_patterns\_template.md') (Join-Path $spDst '_template.md')

# ===============================================================
# 3. Knowledge (taxonomy + playbook + competitions, NO solved/ data)
# ===============================================================
Write-Host '[3/7] Knowledge (skeleton)' -ForegroundColor Green
$knDst = Join-Path $DistDir 'knowledge'
New-Item -ItemType Directory -Path $knDst -Force | Out-Null

# taxonomy + README
Copy-IfExists (Join-Path $ProjRoot 'knowledge\taxonomy.yaml') (Join-Path $knDst 'taxonomy.yaml')
Copy-IfExists (Join-Path $ProjRoot 'knowledge\README.md')     (Join-Path $knDst 'README.md')
Copy-IfExists (Join-Path $ProjRoot 'knowledge\tools_cheatsheet.md') (Join-Path $knDst 'tools_cheatsheet.md')
Copy-IfExists (Join-Path $ProjRoot 'knowledge\CLI_快速参考.md') (Join-Path $knDst 'CLI_快速参考.md')

# playbook (methodology, not data - include)
Copy-IfExists (Join-Path $ProjRoot 'knowledge\playbook') (Join-Path $knDst 'playbook') -Recurse

# competitions (public info - include)
Copy-IfExists (Join-Path $ProjRoot 'knowledge\competitions') (Join-Path $knDst 'competitions') -Recurse

# sop, tools, wp_index, solved → empty placeholders
foreach ($sub in @('sop','tools','wp_index','solved')) {
    $subDir = Join-Path $knDst $sub
    New-Item -ItemType Directory -Path $subDir -Force | Out-Null
    Set-Content (Join-Path $subDir '.gitkeep') '' -Encoding ASCII
    Copy-IfExists (Join-Path $ProjRoot "knowledge\$sub\README.md") (Join-Path $subDir 'README.md')
}

# ===============================================================
# 4. Strategies + Modes + Roles + Education
# ===============================================================
Write-Host '[4/7] Strategies, Modes, Roles, Education' -ForegroundColor Green
Copy-IfExists (Join-Path $ProjRoot 'strategies') (Join-Path $DistDir 'strategies') -Recurse
Copy-IfExists (Join-Path $ProjRoot 'modes')      (Join-Path $DistDir 'modes')      -Recurse
Copy-IfExists (Join-Path $ProjRoot 'roles')      (Join-Path $DistDir 'roles')      -Recurse
Copy-IfExists (Join-Path $ProjRoot 'education')  (Join-Path $DistDir 'education')  -Recurse

# ===============================================================
# 5. .windsurf (workflows + rules)
# ===============================================================
Write-Host '[5/7] .windsurf config' -ForegroundColor Green
Copy-IfExists (Join-Path $ProjRoot '.windsurf') (Join-Path $DistDir '.windsurf') -Recurse

# ===============================================================
# 6. Install scripts + bootstrap
# ===============================================================
Write-Host '[6/7] Install + Bootstrap' -ForegroundColor Green
$installDst = Join-Path $DistDir 'install'
New-Item -ItemType Directory -Path $installDst -Force | Out-Null

# From share/install
$shareInstall = Join-Path $ProjRoot 'share\install'
if (Test-Path $shareInstall) {
    Get-ChildItem $shareInstall -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $installDst $_.Name)
    }
}

# Generic scripts
$scriptDst = Join-Path $DistDir 'scripts'
New-Item -ItemType Directory -Path $scriptDst -Force | Out-Null
$genericScripts = @(
    'env_healthcheck.ps1','env_healthcheck.sh',
    'install_wsl_tools.sh','install_windows_tools.ps1',
    'bootstrap_new_machine.ps1','ask_advisor.py','README.md'
)
foreach ($s in $genericScripts) {
    Copy-IfExists (Join-Path $ProjRoot "scripts\$s") (Join-Path $scriptDst $s)
}

# Bootstrap script (download training data)
Copy-IfExists (Join-Path $ProjRoot 'bootstrap.ps1') (Join-Path $DistDir 'bootstrap.ps1')

# Case template
$caseDst = Join-Path $DistDir 'cases\_template'
foreach ($d in @('wp_batches','artifacts','evidence','notes','launch')) {
    New-Item -ItemType Directory -Path (Join-Path $caseDst $d) -Force | Out-Null
}
Set-Content (Join-Path $caseDst 'README.md') "# Case Template`nCopy this folder for each new competition." -Encoding UTF8

# Worklog
New-Item -ItemType Directory -Path (Join-Path $DistDir 'worklog') -Force | Out-Null
Copy-IfExists (Join-Path $ProjRoot 'worklog\README.md') (Join-Path $DistDir 'worklog\README.md')

# ===============================================================
# 7. Create zip
# ===============================================================
Write-Host '[7/7] Create zip' -ForegroundColor Green

Add-Type -Assembly 'System.IO.Compression.FileSystem'
[System.IO.Compression.ZipFile]::CreateFromDirectory($DistDir, $ZipPath)

$sizeMB = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
$fileCount = (Get-ChildItem -Recurse $DistDir -File).Count

# Cleanup
Remove-Item -Recurse -Force $DistDir

Write-Host ''
Write-Host '================================================' -ForegroundColor Cyan
Write-Host '  ForensicAI Dist Package Ready' -ForegroundColor Cyan
Write-Host ''
Write-Host "  Files: $fileCount"
Write-Host "  ZIP:   $ZipPath ($sizeMB MB)"
Write-Host ''
Write-Host '  Next steps for recipient:'
Write-Host '    1. Unzip'
Write-Host '    2. Run: .\bootstrap.ps1 -DataSource github'
Write-Host '       (downloads training data + installs tools)'
Write-Host '    3. Open in Windsurf/Cursor/Claude Code'
Write-Host '    4. AI reads AGENTS.md and starts working'
Write-Host ''
Write-Host '================================================' -ForegroundColor Cyan
