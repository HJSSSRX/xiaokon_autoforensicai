<#
.SYNOPSIS
    Detect local accelerator side-effects (Watt Toolkit / Steam++ symptoms).

.DESCRIPTION
    Three-stage probe:
      Stage 0: residual loopback proxy in HKCU Internet Settings (breaks
               Electron apps like Windsurf even after accelerator quits).
      Stage 1: github.com DNS resolution check (loopback / null IPs => DNS hijack).
      Stage 2: TLS probe via git+openssl backend (cert verify failure => TLS MITM).

    Exit codes:
        0 = clean
        1 = hijacked / residue detected (see message for fix)
        2 = DNS unreachable, no resolution at all

.PARAMETER Quiet
    Suppress success output (still prints failure / hijack diagnostics).

.NOTES
    Trigger: pre-flight before any push to xiaokon-all / framework / data.
#>
[CmdletBinding()]
param(
    [switch]$Quiet
)

# Stage 0: residual local proxy in registry (accelerator side-effect).
# Symptom: HKCU\...\Internet Settings\ProxyServer = 127.0.0.1:<port> even when
# ProxyEnable=0. Electron apps (Windsurf / VS Code) may still attempt that
# dead loopback port, surfacing as misleading "third-party model provider"
# errors. Seen with Watt Toolkit / Steam++ residue.
$inet = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
try {
    $proxySrv = (Get-ItemProperty -Path $inet -ErrorAction Stop).ProxyServer
} catch { $proxySrv = $null }
if ($proxySrv -match '127\.0\.0\.1|localhost') {
    Write-Host "[NET][PROXY-RESIDUE] HKCU ProxyServer = $proxySrv" -ForegroundColor Yellow
    Write-Host '             local accelerator left a dead loopback proxy in registry'
    Write-Host '             Electron apps (Windsurf) may still hit it and fail'
    Write-Host "  Fix: Set-ItemProperty -Path `"$inet`" -Name ProxyServer -Value `"`""
    exit 1
}

try {
    $rec = Resolve-DnsName -Name github.com -Type A -DnsOnly -ErrorAction Stop
} catch {
    Write-Host '[NET][FAIL] Resolve-DnsName github.com error:' -ForegroundColor Red
    Write-Host "         $($_.Exception.Message)"
    exit 2
}

$ips = @($rec | Where-Object { $_.IPAddress } | ForEach-Object { $_.IPAddress })
if (-not $ips) {
    Write-Host '[NET][FAIL] no A records returned for github.com' -ForegroundColor Red
    exit 2
}

$bad = @($ips | Where-Object { $_ -match '^(127\.|0\.0\.0\.0$|::1$)' })
if ($bad) {
    Write-Host "[NET][HIJACK-DNS] github.com -> $($ips -join ', ')" -ForegroundColor Yellow
    Write-Host '             DNS intercepted by local accelerator (Watt Toolkit / Steam++)'
    Write-Host '  Fix: 1) quit accelerator  OR  2) git -c http.sslBackend=schannel ...'
    exit 1
}

# Stage 2: TLS probe (DNS clean does NOT mean cert is real; accelerator may MITM TLS).
# Strategy: use git+openssl backend (which uses git's bundled CA, NOT Windows trust store)
# and ls-remote against a public empty repo. If the accelerator's MITM cert is only
# trusted by Windows but not by openssl bundle, this call will fail with cert error.
if (-not $Quiet) {
    Write-Host "[NET] DNS ok ($($ips -join ', ')); probing TLS via openssl backend..." -ForegroundColor Gray
}
$probe = & git -c http.sslBackend=openssl `
    -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=10 `
    ls-remote --exit-code https://github.com/octocat/Hello-World.git HEAD 2>&1
$probeCode = $LASTEXITCODE
if ($probeCode -ne 0) {
    Write-Host "[NET][HIJACK-TLS] openssl cannot verify github.com cert" -ForegroundColor Yellow
    Write-Host "             output: $probe"
    Write-Host "             likely TLS MITM by accelerator (its cert is in Windows store, not git's CA bundle)"
    Write-Host '  Fix: 1) quit accelerator  OR  2) git -c http.sslBackend=schannel ...'
    exit 1
}

if (-not $Quiet) {
    Write-Host "[NET][OK] github.com DNS + TLS clean" -ForegroundColor Green
}
exit 0
