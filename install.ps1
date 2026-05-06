<#
.SYNOPSIS
    AutoForensicAI first-time setup and tool installer.
    Reads tools/manifest.yaml and installs everything needed.

.DESCRIPTION
    On first clone, run this script to set up the environment.
    It installs scoop (if missing), then installs tools by role.

.EXAMPLE
    .\install.ps1                    # Install core + all roles
    .\install.ps1 -Role forensics    # Install core + forensics tools
    .\install.ps1 -Role pentest      # Install core + pentest tools
    .\install.ps1 -Check             # Check status only, no install
    .\install.ps1 -Docker            # Also pull Docker images
    .\install.ps1 -WSL               # Also install WSL tools
#>

param(
    [ValidateSet("all","core","forensics","network","reverse","stego_crypto","pentest","python_packages")]
    [string]$Role = "all",
    [switch]$Check,
    [switch]$Docker,
    [switch]$WSL,
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── Helpers ───

function Write-Status($icon, $text, $color) {
    Write-Host "  $icon " -NoNewline -ForegroundColor $color
    Write-Host $text
}

function Write-Ok($text)      { Write-Status "[OK]" $text Green }
function Write-Miss($text)    { Write-Status "[--]" $text Yellow }
function Write-Info($text)    { Write-Status "[..]" $text Cyan }
function Write-Fail($text)    { Write-Status "[!!]" $text Red }
function Write-Section($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }

function Test-CommandExists($cmd) {
    try {
        $null = Get-Command $cmd -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Find-ToolPath($toolDef) {
    # Check PATH first
    try {
        $found = Get-Command $toolDef.check_cmd.Split(" ")[0] -ErrorAction Stop
        return $found.Source
    } catch {}

    # Check known_paths
    if ($toolDef.known_paths) {
        foreach ($p in $toolDef.known_paths) {
            $expanded = $p -replace "~", $env:USERPROFILE
            if (Test-Path $expanded) { return $expanded }
        }
    }
    return $null
}

# ─── Parse manifest.yaml (minimal YAML parser, no external deps) ───

function Parse-Manifest {
    $manifest = @{}
    $yamlPath = Join-Path $ScriptRoot "tools\manifest.yaml"
    if (-not (Test-Path $yamlPath)) {
        Write-Fail "tools/manifest.yaml not found!"
        exit 1
    }

    # Use Python to parse YAML and output as JSON
    $json = python -c @"
import yaml, json, sys
with open(r'$yamlPath', encoding='utf-8') as f:
    data = yaml.safe_load(f)
print(json.dumps(data, ensure_ascii=False))
"@ 2>$null

    if (-not $json) {
        Write-Fail "Failed to parse manifest.yaml (is Python + pyyaml installed?)"
        Write-Info "Trying: pip install pyyaml"
        pip install pyyaml -q 2>$null
        $json = python -c @"
import yaml, json
with open(r'$yamlPath', encoding='utf-8') as f:
    data = yaml.safe_load(f)
print(json.dumps(data, ensure_ascii=False))
"@
    }

    return $json | ConvertFrom-Json
}

# ─── Scoop setup ───

function Ensure-Scoop {
    if (Test-CommandExists "scoop") {
        Write-Ok "scoop already installed"
        return
    }
    Write-Info "Installing scoop..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Ok "scoop installed"
    } catch {
        Write-Fail "scoop install failed: $_"
    }
}

function Ensure-ScoopBuckets($buckets) {
    $existing = scoop bucket list 2>$null | ForEach-Object { $_.Name }
    foreach ($b in $buckets) {
        if ($existing -contains $b) { continue }
        Write-Info "Adding scoop bucket: $b"
        scoop bucket add $b 2>$null
    }
}

# ─── Install functions ───

function Install-ViaPip($package) {
    Write-Info "pip install $package ..."
    pip install $package -q 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Ok "$package installed via pip" }
    else { Write-Fail "$package pip install failed" }
}

function Install-ViaScoop($package, $bucket) {
    $cmd = "scoop install $package"
    if ($bucket -and $bucket -ne "main") { $cmd = "scoop install ${bucket}/${package}" }
    Write-Info $cmd
    Invoke-Expression $cmd 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Ok "$package installed via scoop" }
    else { Write-Fail "$package scoop install failed" }
}

function Install-ViaWinget($id) {
    Write-Info "winget install $id ..."
    winget install --id $id --accept-package-agreements --accept-source-agreements -e 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Ok "$id installed via winget" }
    else { Write-Fail "$id winget install failed" }
}

function Install-Tool($name, $toolDef, $checkOnly) {
    $checkCmd = $null
    if ($toolDef.check_cmd) { $checkCmd = $toolDef.check_cmd.Split(" ")[0] }

    # Check if already available
    $path = $null
    if ($checkCmd) {
        if (Test-CommandExists $checkCmd) {
            $loc = (Get-Command $checkCmd -ErrorAction SilentlyContinue).Source
            Write-Ok "$name ($loc)"
            return
        }
    }

    # Check known_paths
    if ($toolDef.known_paths) {
        foreach ($p in $toolDef.known_paths) {
            $expanded = $p -replace "~", $env:USERPROFILE
            if (Test-Path $expanded) {
                Write-Ok "$name ($expanded) [not in PATH]"
                return
            }
        }
    }

    # Check via check_cmd for pip packages
    if ($checkCmd -eq "python") {
        try {
            $result = Invoke-Expression $toolDef.check_cmd 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "$name (python package)"
                return
            }
        } catch {}
    }

    if ($checkOnly) {
        $hint = ""
        if ($toolDef.install -and $toolDef.install.Count -gt 0) {
            $first = $toolDef.install[0]
            $hint = " -> $($first.type): $($first.package ?? $first.id ?? $first.image ?? $first.url)"
        }
        Write-Miss "$name$hint"
        return
    }

    # Try install methods in order
    if (-not $toolDef.install -or $toolDef.install.Count -eq 0) {
        Write-Miss "$name (no install method)"
        return
    }

    $installed = $false
    foreach ($method in $toolDef.install) {
        switch ($method.type) {
            "pip" {
                Install-ViaPip $method.package
                $installed = $true
                break
            }
            "scoop" {
                Install-ViaScoop $method.package $method.bucket
                $installed = $true
                break
            }
            "winget" {
                Install-ViaWinget $method.id
                $installed = $true
                break
            }
            "wsl" {
                if ($WSL) {
                    Write-Info "wsl apt install $($method.package) ..."
                    wsl sudo apt install -y $method.package 2>$null
                    $installed = $true
                } else {
                    Write-Miss "$name (WSL only, use -WSL flag)"
                }
                break
            }
            "docker" {
                if ($Docker) {
                    Write-Info "docker pull $($method.image) ..."
                    docker pull $method.image 2>$null
                    $installed = $true
                } else {
                    Write-Miss "$name (Docker only, use -Docker flag)"
                }
                break
            }
            "manual" {
                Write-Miss "$name -> manual download: $($method.url)"
                break
            }
        }
        if ($installed) { break }
    }
}

# ─── Main ───

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor White
Write-Host "║   AutoForensicAI Tool Installer v1.0     ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor White

if (-not (Test-CommandExists "python")) {
    Write-Fail "Python not found! Install Python 3.10+ first."
    Write-Info "Download: https://www.python.org/downloads/"
    Write-Info "Or: winget install Python.Python.3.12"
    exit 1
}

$manifest = Parse-Manifest
if (-not $manifest) { exit 1 }

# Step 1: Ensure scoop
if (-not $Check) {
    Ensure-Scoop
    if ($manifest.meta.scoop_buckets) {
        Ensure-ScoopBuckets $manifest.meta.scoop_buckets
    }
}

# Step 2: Install/check sections
$sections = @("core", "python_packages")
if ($Role -eq "all") {
    $sections = @("core", "python_packages", "forensics", "network", "reverse", "stego_crypto", "pentest")
} elseif ($Role -ne "core" -and $Role -ne "python_packages") {
    $sections += $Role
}

foreach ($section in $sections) {
    $sectionData = $manifest.$section
    if (-not $sectionData) { continue }

    Write-Section $section.ToUpper()

    $sectionData.PSObject.Properties | ForEach-Object {
        Install-Tool $_.Name $_.Value $Check
    }
}

# Step 3: Docker images
if ($Docker -and $manifest.docker_images) {
    Write-Section "DOCKER IMAGES"
    if (-not (Test-CommandExists "docker")) {
        Write-Fail "Docker not installed!"
        Write-Info "Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    } else {
        $manifest.docker_images.PSObject.Properties | ForEach-Object {
            $img = $_.Value
            Write-Info "docker pull $($img.image) ..."
            docker pull $img.image 2>$null
            if ($img.note) { Write-Info "  Note: $($img.note)" }
        }
    }
}

# Summary
Write-Host ""
Write-Host "─────────────────────────────────────────" -ForegroundColor White
if ($Check) {
    Write-Host "Check complete. Run without -Check to install missing tools." -ForegroundColor White
} else {
    Write-Host "Setup complete!" -ForegroundColor Green
    Write-Host "Tool locations: python tools\tool_status.py" -ForegroundColor White
    Write-Host "Manifest: tools\manifest.yaml" -ForegroundColor White
}
Write-Host ""
