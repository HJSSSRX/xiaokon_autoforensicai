#Requires -Version 5.1
<#
.SYNOPSIS
  ForensicAI Bootstrap — download training data + auto-install tools.
  Run this after unzipping the forensicai-starter distribution.

.PARAMETER DataSource
  Where to get training data: 'github', 'release', 'local'

.PARAMETER LocalPath
  Path to local knowledge pack zip (when DataSource = 'local')

.PARAMETER SkipTools
  Skip tool installation, only download data

.EXAMPLE
  .\bootstrap.ps1 -DataSource github
  .\bootstrap.ps1 -DataSource local -LocalPath .\knowledge-pack.zip
  .\bootstrap.ps1 -DataSource release -SkipTools
#>

param(
    [ValidateSet('github','release','local')]
    [string]$DataSource = 'github',

    [string]$LocalPath = '',

    [switch]$SkipTools
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = $PSScriptRoot

Write-Host ''
Write-Host '================================================' -ForegroundColor Cyan
Write-Host '  ForensicAI Bootstrap' -ForegroundColor Cyan
Write-Host '================================================' -ForegroundColor Cyan

# --- Read manifest ---
$manifestPath = Join-Path $ProjectRoot 'knowledge\manifest.yaml'
if (-not (Test-Path $manifestPath)) {
    Write-Host '[ERROR] knowledge/manifest.yaml not found. Are you in the right directory?' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '[1/4] Reading manifest...' -ForegroundColor Green

# Simple YAML parser (for key fields only)
$manifestContent = Get-Content $manifestPath -Raw -Encoding UTF8

# Extract repo URL from manifest
$repoMatch = [regex]::Match($manifestContent, 'repo:\s*"([^"]+)"')
$repoUrl = if ($repoMatch.Success) { $repoMatch.Groups[1].Value } else { '' }

$releaseMatch = [regex]::Match($manifestContent, 'url:\s*"([^"]+)"')
$releaseUrl = if ($releaseMatch.Success) { $releaseMatch.Groups[1].Value } else { '' }

Write-Host "  Data source: $DataSource"

# --- Download training data ---
Write-Host ''
Write-Host '[2/4] Downloading training data...' -ForegroundColor Green

$tempDir = Join-Path $env:TEMP 'forensicai-data'
if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }

switch ($DataSource) {
    'github' {
        if ($repoUrl -match 'YOUR_USERNAME') {
            Write-Host '  [WARN] Repository URL not configured in manifest.yaml' -ForegroundColor Yellow
            Write-Host '  Please edit knowledge/manifest.yaml and set sources.github.repo' -ForegroundColor Yellow
            Write-Host ''
            Write-Host '  For now, you can:' -ForegroundColor Yellow
            Write-Host '    1. Clone manually: git clone <your-repo> _data_temp' -ForegroundColor Yellow
            Write-Host '    2. Copy knowledge data into knowledge/solved/' -ForegroundColor Yellow
            Write-Host '    3. Re-run: .\bootstrap.ps1 -DataSource local -LocalPath <zip>' -ForegroundColor Yellow
            exit 1
        }
        Write-Host "  Cloning from $repoUrl ..."
        git clone --depth 1 "https://github.com/$repoUrl.git" $tempDir
        if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
    }
    'release' {
        if ($releaseUrl -match 'YOUR_USERNAME') {
            Write-Host '  [WARN] Release URL not configured.' -ForegroundColor Yellow
            exit 1
        }
        Write-Host "  Downloading from $releaseUrl ..."
        $zipTemp = Join-Path $env:TEMP 'forensicai-data.zip'
        Invoke-WebRequest -Uri $releaseUrl -OutFile $zipTemp
        Expand-Archive -Path $zipTemp -DestinationPath $tempDir -Force
        Remove-Item $zipTemp
    }
    'local' {
        if (-not $LocalPath -or -not (Test-Path $LocalPath)) {
            Write-Host "  [ERROR] Local path not found: $LocalPath" -ForegroundColor Red
            exit 1
        }
        Write-Host "  Extracting from $LocalPath ..."
        Expand-Archive -Path $LocalPath -DestinationPath $tempDir -Force
    }
}

# --- Merge downloaded data into project ---
Write-Host ''
Write-Host '[3/4] Merging training data...' -ForegroundColor Green

$mergeCount = 0

# knowledge/solved/
$srcSolved = Join-Path $tempDir 'knowledge\solved'
if (Test-Path $srcSolved) {
    $dstSolved = Join-Path $ProjectRoot 'knowledge\solved'
    Get-ChildItem $srcSolved -Directory | ForEach-Object {
        $target = Join-Path $dstSolved $_.Name
        if (-not (Test-Path $target)) { New-Item -ItemType Directory $target -Force | Out-Null }
        Copy-Item (Join-Path $_.FullName '*') $target -Force -Recurse
        $count = (Get-ChildItem $_.FullName -File -Filter '*.yaml').Count
        Write-Host "  [OK] knowledge/solved/$($_.Name)/ ($count files)" -ForegroundColor Green
        $mergeCount += $count
    }
}

# knowledge/wp_index/
$srcWp = Join-Path $tempDir 'knowledge\wp_index'
if (Test-Path $srcWp) {
    $dstWp = Join-Path $ProjectRoot 'knowledge\wp_index'
    Copy-Item (Join-Path $srcWp '*') $dstWp -Force
    $count = (Get-ChildItem $srcWp -File).Count
    Write-Host "  [OK] knowledge/wp_index/ ($count files)" -ForegroundColor Green
    $mergeCount += $count
}

# knowledge/sop/
$srcSop = Join-Path $tempDir 'knowledge\sop'
if (Test-Path $srcSop) {
    $dstSop = Join-Path $ProjectRoot 'knowledge\sop'
    Copy-Item (Join-Path $srcSop '*') $dstSop -Force -Recurse
    Write-Host "  [OK] knowledge/sop/" -ForegroundColor Green
}

# AI_BRAIN/solved_patterns/
$srcPat = Join-Path $tempDir 'AI_BRAIN\solved_patterns'
if (Test-Path $srcPat) {
    $dstPat = Join-Path $ProjectRoot 'AI_BRAIN\solved_patterns'
    Copy-Item (Join-Path $srcPat '*') $dstPat -Force
    $count = (Get-ChildItem $srcPat -File -Filter '*.md').Count
    Write-Host "  [OK] AI_BRAIN/solved_patterns/ ($count files)" -ForegroundColor Green
    $mergeCount += $count
}

Write-Host "  Total merged: $mergeCount files"

# Cleanup
Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

# --- Install tools ---
if (-not $SkipTools) {
    Write-Host ''
    Write-Host '[4/4] Installing tools (reading manifest)...' -ForegroundColor Green

    # Check if WSL is available
    $hasWSL = $false
    try {
        $wslCheck = wsl --list --quiet 2>&1
        $hasWSL = ($LASTEXITCODE -eq 0)
    } catch { }

    if ($hasWSL) {
        Write-Host '  WSL detected. Running Linux tool checks...' -ForegroundColor Green

        # Check Linux tools from manifest
        $linuxTools = @(
            @{name='sqlite3';   check='sqlite3 --version';          install='sudo apt-get install -y sqlite3'},
            @{name='sleuthkit'; check='mmls -V 2>&1 | head -1';    install='sudo apt-get install -y sleuthkit'},
            @{name='exiftool';  check='exiftool -ver';              install='sudo apt-get install -y libimage-exiftool-perl'},
            @{name='radare2';   check='r2 -v 2>&1 | head -1';     install='sudo apt-get install -y radare2'},
            @{name='hashcat';   check='hashcat --version';          install='sudo apt-get install -y hashcat'}
        )

        $missing = @()
        foreach ($tool in $linuxTools) {
            $result = wsl bash -c "$($tool.check)" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  [MISS] $($tool.name)" -ForegroundColor Yellow
                $missing += $tool
            } else {
                Write-Host "  [OK]   $($tool.name)" -ForegroundColor Green
            }
        }

        if ($missing.Count -gt 0) {
            Write-Host ''
            Write-Host "  $($missing.Count) tools missing. Install now? (y/N)" -ForegroundColor Yellow
            $answer = Read-Host
            if ($answer -eq 'y' -or $answer -eq 'Y') {
                $installCmd = ($missing | ForEach-Object { $_.install }) -join ' && '
                Write-Host "  Running: $installCmd" -ForegroundColor Cyan
                wsl bash -c $installCmd
            }
        }

        # Check Python packages
        Write-Host ''
        Write-Host '  Checking Python packages...' -ForegroundColor Green
        $pyPkgs = @(
            @{name='pycryptodomex'; check="python3 -c 'from Cryptodome.Cipher import AES' 2>&1"},
            @{name='openpyxl';      check="python3 -c 'import openpyxl' 2>&1"}
        )
        $missingPy = @()
        foreach ($pkg in $pyPkgs) {
            $result = wsl bash -c $pkg.check 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  [MISS] $($pkg.name)" -ForegroundColor Yellow
                $missingPy += $pkg.name
            } else {
                Write-Host "  [OK]   $($pkg.name)" -ForegroundColor Green
            }
        }
        if ($missingPy.Count -gt 0) {
            $pipCmd = "pip install " + ($missingPy -join ' ')
            Write-Host "  Install with: wsl bash -c '$pipCmd'" -ForegroundColor Yellow
        }

    } else {
        Write-Host '  [WARN] WSL not detected. Skipping Linux tool checks.' -ForegroundColor Yellow
        Write-Host '  Install WSL first: wsl --install' -ForegroundColor Yellow
    }

    # Check Windows tools
    Write-Host ''
    Write-Host '  Checking Windows tools...' -ForegroundColor Green
    $winTools = @(
        @{name='7zip'; check='7z'},
        @{name='git';  check='git --version'}
    )
    foreach ($tool in $winTools) {
        try {
            $null = & cmd /c "where $($tool.check.Split(' ')[0]) 2>nul"
            Write-Host "  [OK]   $($tool.name)" -ForegroundColor Green
        } catch {
            Write-Host "  [MISS] $($tool.name)" -ForegroundColor Yellow
        }
    }

} else {
    Write-Host ''
    Write-Host '[4/4] Tool install skipped (-SkipTools)' -ForegroundColor Yellow
}

# --- Summary ---
Write-Host ''
Write-Host '================================================' -ForegroundColor Cyan
Write-Host '  Bootstrap Complete' -ForegroundColor Cyan
Write-Host ''
Write-Host '  Next steps:'
Write-Host '    1. Open this folder in Windsurf / Cursor / Claude Code'
Write-Host '    2. AI reads AGENTS.md → selects strategy → starts working'
Write-Host '    3. For education mode: strategies/education_local_solo.yaml'
Write-Host ''
if ($mergeCount -eq 0) {
    Write-Host '  [WARN] No training data was merged. Check your data source.' -ForegroundColor Yellow
}
Write-Host '================================================' -ForegroundColor Cyan
