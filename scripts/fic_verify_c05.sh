#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
PCD=/tmp/pc_data

CLASH_DIR="$PCD/root/.local/share/io.github.clash-verge-rev.clash-verge-rev"
echo "=== Clash Verge 目录 ==="
SUDO ls -la $CLASH_DIR/ 2>/dev/null
echo ""
echo "=== 全局搜 9527 ==="
SUDO grep -rn '9527' $CLASH_DIR 2>/dev/null | head -20
echo ""
echo "=== 全局搜所有端口号字段 ==="
SUDO grep -rnE 'port:|-port|port =|external-controller|socks-port|mixed-port' $CLASH_DIR 2>/dev/null | head -40
echo ""
echo "=== verge.yaml (用户设置) ==="
SUDO cat $CLASH_DIR/verge.yaml 2>/dev/null | head -40
echo ""
echo "=== config.yaml / main config ==="
SUDO find $CLASH_DIR -name 'config*.yaml' -o -name 'profiles.yaml' 2>/dev/null | head
echo ""
echo "=== 所有 .yaml ==="
for f in $(SUDO find $CLASH_DIR -name '*.yaml' 2>/dev/null); do
  echo ""
  echo "--- $f ---"
  SUDO grep -E 'port|9527|7897|controller|socks' "$f" 2>/dev/null | head -20
done
echo ""
echo "=== profiles/ 里的具体 profile 文件 ==="
SUDO ls $CLASH_DIR/profiles/ 2>/dev/null | head
SUDO head -30 $CLASH_DIR/profiles/*.yaml 2>/dev/null | head -80
