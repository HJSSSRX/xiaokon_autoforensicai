<#
.SYNOPSIS
    AutoForensicAI bootstrap script — check and install tools by role.

.DESCRIPTION
    Checks which CLI tools are available, reports missing ones,
    and optionally installs them.

.EXAMPLE
    .\bootstrap.ps1 -Check
    .\bootstrap.ps1 -Role computer
    .\bootstrap.ps1 -Role web
    .\bootstrap.ps1 -Role all
#>

param(
    [ValidateSet("computer", "mobile", "network", "web", "stego_crypto", "reverse", "all")]
    [string]$Role = "",
    [switch]$Check,
    [switch]$Install
)

$ErrorActionPreference = "Continue"

# Tool definitions: name → check command → install hint
$Tools = @{
    computer = @(
        @{ Name="volatility3";  Cmd="vol";         Check="vol -h";           Hint="pip install volatility3" }
        @{ Name="strings";      Cmd="strings";     Check="strings --version"; Hint="Install via SysInternals or binutils" }
        @{ Name="exiftool";     Cmd="exiftool";    Check="exiftool -ver";    Hint="choco install exiftool" }
        @{ Name="regripper";    Cmd="rip";         Check="rip -h";           Hint="choco install regripper (or manual install)" }
        @{ Name="chainsaw";     Cmd="chainsaw";    Check="chainsaw -h";      Hint="Download from https://github.com/WithSecureLabs/chainsaw/releases" }
        @{ Name="hayabusa";     Cmd="hayabusa";    Check="hayabusa -h";      Hint="Download from https://github.com/Yamato-Security/hayabusa/releases" }
        @{ Name="binwalk";      Cmd="binwalk";     Check="binwalk -h";       Hint="pip install binwalk" }
        @{ Name="foremost";     Cmd="foremost";    Check="foremost -V";      Hint="Linux: apt install foremost" }
        @{ Name="sqlite3";      Cmd="sqlite3";     Check="sqlite3 --version"; Hint="choco install sqlite" }
    )
    mobile = @(
        @{ Name="adb";          Cmd="adb";         Check="adb version";      Hint="choco install adb" }
        @{ Name="aleapp";       Cmd="aleapp";      Check="aleapp -h";        Hint="pip install aleapp" }
        @{ Name="ileapp";       Cmd="ileapp";      Check="ileapp -h";        Hint="pip install ileapp" }
        @{ Name="mvt";          Cmd="mvt-android"; Check="mvt-android -h";   Hint="pip install mvt" }
        @{ Name="sqlite3";      Cmd="sqlite3";     Check="sqlite3 --version"; Hint="choco install sqlite" }
        @{ Name="strings";      Cmd="strings";     Check="strings --version"; Hint="SysInternals or binutils" }
        @{ Name="exiftool";     Cmd="exiftool";    Check="exiftool -ver";    Hint="choco install exiftool" }
    )
    network = @(
        @{ Name="tshark";       Cmd="tshark";      Check="tshark -v";        Hint="Install Wireshark (includes tshark)" }
        @{ Name="nmap";         Cmd="nmap";        Check="nmap --version";   Hint="choco install nmap" }
        @{ Name="curl";         Cmd="curl";        Check="curl --version";   Hint="Built into Windows 10+" }
    )
    web = @(
        @{ Name="nmap";         Cmd="nmap";        Check="nmap --version";   Hint="choco install nmap" }
        @{ Name="sqlmap";       Cmd="sqlmap";      Check="sqlmap --version"; Hint="pip install sqlmap" }
        @{ Name="ffuf";         Cmd="ffuf";        Check="ffuf -V";          Hint="go install github.com/ffuf/ffuf/v2@latest" }
        @{ Name="gobuster";     Cmd="gobuster";    Check="gobuster version"; Hint="go install github.com/OJ/gobuster/v3@latest" }
        @{ Name="nuclei";       Cmd="nuclei";      Check="nuclei -version";  Hint="go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" }
        @{ Name="nikto";        Cmd="nikto";       Check="nikto -Version";   Hint="apt install nikto (or run via Docker)" }
        @{ Name="hydra";        Cmd="hydra";       Check="hydra -h";         Hint="apt install hydra (or run via Docker/WSL)" }
        @{ Name="curl";         Cmd="curl";        Check="curl --version";   Hint="Built into Windows 10+" }
    )
    stego_crypto = @(
        @{ Name="steghide";     Cmd="steghide";    Check="steghide --help";  Hint="apt install steghide (Linux/WSL)" }
        @{ Name="zsteg";        Cmd="zsteg";       Check="zsteg -h";         Hint="gem install zsteg" }
        @{ Name="exiftool";     Cmd="exiftool";    Check="exiftool -ver";    Hint="choco install exiftool" }
        @{ Name="binwalk";      Cmd="binwalk";     Check="binwalk -h";       Hint="pip install binwalk" }
        @{ Name="john";         Cmd="john";        Check="john --help";      Hint="Download from https://www.openwall.com/john/" }
        @{ Name="hashcat";      Cmd="hashcat";     Check="hashcat --version"; Hint="Download from https://hashcat.net/hashcat/" }
        @{ Name="strings";      Cmd="strings";     Check="strings --version"; Hint="SysInternals or binutils" }
    )
    reverse = @(
        @{ Name="ghidra";       Cmd="ghidraRun";   Check="ghidraRun -h";     Hint="Download from https://ghidra-sre.org/" }
        @{ Name="radare2";      Cmd="r2";          Check="r2 -v";            Hint="choco install radare2" }
        @{ Name="strings";      Cmd="strings";     Check="strings --version"; Hint="SysInternals or binutils" }
        @{ Name="python3";      Cmd="python";      Check="python --version"; Hint="choco install python" }
    )
}

function Test-Tool {
    param([string]$Cmd)
    try {
        $null = Get-Command $Cmd -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Show-RoleTools {
    param([string]$RoleName, [array]$ToolList)

    Write-Host "`n=== $RoleName ===" -ForegroundColor Cyan
    $installed = 0
    $missing = 0

    foreach ($tool in $ToolList) {
        if (Test-Tool $tool.Cmd) {
            Write-Host "  [OK] $($tool.Name)" -ForegroundColor Green
            $installed++
        } else {
            Write-Host "  [--] $($tool.Name)  ->  $($tool.Hint)" -ForegroundColor Yellow
            $missing++
        }
    }

    Write-Host "  Installed: $installed / $($installed + $missing)" -ForegroundColor White
}

# Main logic
if ($Check -or (-not $Role -and -not $Install)) {
    Write-Host "`nAutoForensicAI — Tool Status Check" -ForegroundColor White
    Write-Host "==================================" -ForegroundColor White

    foreach ($key in $Tools.Keys | Sort-Object) {
        Show-RoleTools -RoleName $key -ToolList $Tools[$key]
    }

    Write-Host "`nRun with -Role <name> to see specific role tools."
    Write-Host "Install hints are suggestions — actual method depends on your OS."
    exit 0
}

if ($Role -eq "all") {
    foreach ($key in $Tools.Keys | Sort-Object) {
        Show-RoleTools -RoleName $key -ToolList $Tools[$key]
    }
} elseif ($Tools.ContainsKey($Role)) {
    Show-RoleTools -RoleName $Role -ToolList $Tools[$Role]
} else {
    Write-Host "Unknown role: $Role" -ForegroundColor Red
    Write-Host "Available roles: $($Tools.Keys -join ', ')"
}
