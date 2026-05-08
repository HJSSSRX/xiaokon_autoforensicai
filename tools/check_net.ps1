<#
.SYNOPSIS
    Detect github.com DNS hijack (Watt Toolkit / Steam++ Accelerator symptom).

.DESCRIPTION
    Resolves github.com via DNS and checks if any returned IP falls into
    loopback / null / IPv6-loopback ranges, which indicates the local
    accelerator software is intercepting GitHub traffic.

    Exit codes:
        0 = clean, github.com resolves to public IPs
        1 = hijacked, push must use -c http.sslBackend=schannel
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
