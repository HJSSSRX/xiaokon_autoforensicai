#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
echo "$PW" | sudo -S apt-get install -y btrfs-progs jq 2>&1 | tail -3
command -v btrfs && btrfs --version
command -v jq && jq --version
