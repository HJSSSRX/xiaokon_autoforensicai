#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
PCD="/tmp/pc_data"
PCR="/tmp/pc_root"

echo "=== uos-ai-assistant.desktop ==="
SUDO cat $PCR/usr/share/applications/uos-ai-assistant.desktop 2>/dev/null

echo ""
echo "=== UOS AI 可能的配置目录 (精准 ls，不 find) ==="
for d in \
  "$PCD/root/.config/uos-ai-assistant" \
  "$PCD/root/.config/deepin/uos-ai-assistant" \
  "$PCD/root/.local/share/uos-ai-assistant" \
  "$PCD/root/.local/share/deepin/uos-ai-assistant" \
  "$PCD/root/.cache/deepin/uos-ai-assistant" \
  "$PCD/root/.config/cpis"; do
  echo ""
  echo "--- $d ---"
  SUDO ls -la "$d" 2>/dev/null
done

echo ""
echo "=== cef_user_data 完整 ls (含子目录文件) ==="
SUDO ls -la $PCD/root/.config/cef_user_data/ 2>/dev/null
SUDO ls -la $PCD/root/.config/cef_user_data/Dictionaries/ 2>/dev/null
echo ""
echo "--- cef Local State 找 app 名 ---"
SUDO cat $PCD/root/.config/cef_user_data/Local\ State 2>/dev/null | head -c 2000
echo ""
echo ""
echo "--- 任意 Cookies / Preferences 文件? ---"
SUDO find $PCD/root/.config/cef_user_data -maxdepth 2 -type f 2>/dev/null

echo ""
echo "=== /usr/bin/uos-ai-assistant 二进制存在吗 ==="
SUDO ls -la $PCR/usr/bin/uos-ai-assistant* 2>/dev/null
SUDO ls -la $PCR/opt/apps/uos-ai-assistant 2>/dev/null
SUDO ls -la $PCR/opt/apps/com.deepin.dde.uos-ai-assistant 2>/dev/null
SUDO ls -la $PCR/persistent/linglong/layers/main/ 2>/dev/null | head

echo ""
echo "=== dpkg 装的 ai 包 ==="
SUDO grep -B1 -A1 -E 'Package: .*ai|Package: .*sunlogin|Package: linglong' $PCR/var/lib/dpkg/status 2>/dev/null | grep -E '^Package:' | sort -u

echo ""
echo "=== Software 目录 (root .config 里有 'Software') ==="
SUDO ls $PCD/root/.config/Software/ 2>/dev/null
SUDO find $PCD/root/.config/Software -maxdepth 3 -type f 2>/dev/null

echo ""
echo "=== cpis 是啥 (前面看到) ==="
SUDO ls -la $PCD/root/.config/cpis/ 2>/dev/null
SUDO find $PCD/root/.config/cpis -maxdepth 3 -type f 2>/dev/null | head
SUDO cat $PCD/root/.config/cpis/module/*.json 2>/dev/null | head -50
