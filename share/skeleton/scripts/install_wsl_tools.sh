#!/usr/bin/env bash
# Purpose : Install Linux-side forensics tools into Ubuntu (WSL or native).
# Origin  : 自动化取证 project bootstrap, 2026-04-24.
# Run as : bash install_wsl_tools.sh  (will sudo where needed)
set -euo pipefail

PROJ_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "[*] Project root: $PROJ_ROOT"

# ---------------------------------------------------------------
# 1. apt packages
# ---------------------------------------------------------------
echo ""
echo "[1/3] apt packages"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    sleuthkit ewf-tools afflib-tools \
    libbde-utils libfsapfs-utils \
    tshark \
    python3 python3-pip python3-venv \
    ripgrep jq sqlite3 libimage-exiftool-perl \
    p7zip-full file unzip

# zeek not in Ubuntu 24.04 main repo; try OpenSUSE Build Service, skip on failure
if ! command -v zeek >/dev/null 2>&1; then
    echo "    - attempting zeek from OBS (optional; will skip if fails)"
    UB_CODENAME="$(lsb_release -cs 2>/dev/null || echo noble)"
    case "$UB_CODENAME" in
        noble|jammy|focal)
            OBS="https://download.opensuse.org/repositories/security:/zeek/xUbuntu_$(lsb_release -rs)"
            curl -fsSL "${OBS}/Release.key" 2>/dev/null | sudo gpg --dearmor -o /etc/apt/keyrings/zeek.gpg 2>/dev/null && \
                echo "deb [signed-by=/etc/apt/keyrings/zeek.gpg] ${OBS}/ /" | sudo tee /etc/apt/sources.list.d/zeek.list >/dev/null && \
                sudo apt-get update -qq && \
                sudo apt-get install -y --no-install-recommends zeek zeekctl 2>/dev/null || \
                echo "    - zeek install skipped (OBS unreachable or unsupported)"
            ;;
        *) echo "    - skip zeek: unsupported codename $UB_CODENAME" ;;
    esac
fi

# tshark needs group membership for non-root capture; we only read files, skip.

# ---------------------------------------------------------------
# 2. Python venv + forensic pips
# ---------------------------------------------------------------
# Put venv on Linux native FS: drvfs (/mnt/...) lacks proper POSIX support
# (symlinks/perms) which breaks `python3 -m venv`, and reads are ~10x slower.
VENV_DIR="${VENV_DIR:-$HOME/.venv-forensics}"
echo ""
echo "[2/3] Python venv at $VENV_DIR"
if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
    # remove any half-built venv (e.g. killed mid-init)
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
pip install --upgrade pip wheel
pip install \
    aleapp \
    ileapp \
    pandas openpyxl \
    pycryptodome \
    python-evtx \
    pypff \
    volatility3

# write a pointer file in the project so users can `source` it easily
echo "$VENV_DIR" > "$PROJ_ROOT/.venv-path"

# plaso (log2timeline) works best via apt on Ubuntu 22.04+, try apt first
if ! command -v log2timeline.py >/dev/null 2>&1; then
    echo "    - installing plaso via apt (optional, may not be available on older Ubuntu)"
    sudo apt-get install -y plaso-tools 2>/dev/null || \
        echo "    - plaso-tools not in apt; skip. If needed: pipx install plaso."
fi

# ---------------------------------------------------------------
# 3. Verify
# ---------------------------------------------------------------
echo ""
echo "[3/3] Verification"
check() {
    if command -v "$1" >/dev/null 2>&1; then
        printf "    [OK] %-20s -> %s\n" "$1" "$(command -v "$1")"
    else
        printf "    [--] %-20s MISSING\n" "$1"
    fi
}
check fls
check icat
check mmls
check tsk_recover
check ewfinfo
check tshark
check zeek
check rg
check jq
check sqlite3
check exiftool
check 7z
check aleapp
check ileapp
check vol            # volatility3 entrypoint
check log2timeline.py

echo ""
echo "Done. Activate the venv with: source $PROJ_ROOT/.venv/bin/activate"
