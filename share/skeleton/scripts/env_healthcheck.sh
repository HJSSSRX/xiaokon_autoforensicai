#!/usr/bin/env bash
# 30 秒 WSL 内健康检查。直接: bash scripts/env_healthcheck.sh
set -u
echo "=== 自动化取证 · WSL 健康检查 ==="

OK=0; FAIL=0
ch() {
    if command -v "$1" >/dev/null 2>&1; then
        printf "  [OK] %-15s -> %s\n" "$1" "$(command -v $1)"
        OK=$((OK+1))
    else
        printf "  [--] %-15s MISSING\n" "$1"
        FAIL=$((FAIL+1))
    fi
}

echo ""
echo "[1] 核心 CLI"
for c in fls mmls tsk_recover ewfmount tshark sqlite3 rg jq 7z exiftool file unzip python3; do
    ch "$c"
done

echo ""
echo "[2] venv"
if [[ -f "$HOME/.venv-forensics/bin/activate" ]]; then
    printf "  [OK] venv @ %s\n" "$HOME/.venv-forensics"
    OK=$((OK+1))
    source "$HOME/.venv-forensics/bin/activate"
    for c in aleapp ileapp vol; do ch "$c"; done
else
    printf "  [--] venv 缺失\n"
    FAIL=$((FAIL+1))
fi

echo ""
echo "[3] 网络 / apt"
if timeout 5 apt-cache policy sleuthkit >/dev/null 2>&1; then
    echo "  [OK] apt 可用"
    OK=$((OK+1))
else
    echo "  [--] apt 不可用"
    FAIL=$((FAIL+1))
fi

echo ""
echo "================================="
echo "  PASS: $OK   FAIL: $FAIL"
echo "================================="
if [[ $FAIL -gt 0 ]]; then
    echo "→ 跑: bash scripts/install_wsl_tools.sh"
    exit 1
fi
