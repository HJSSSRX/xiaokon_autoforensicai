#!/usr/bin/env bash
PW=$(cat /mnt/e/项目/自动化取证/cases/.wsl_pw | tr -d '\r\n')
SUDO() { echo "$PW" | sudo -S "$@"; }
PCD="/tmp/pc_data"
PCR="/tmp/pc_root"

echo "==========================================" 
echo "AI 软件确认 - cef_user_data 是哪个 app"
echo "=========================================="
SUDO ls -la $PCD/root/.config/cef_user_data/ 2>/dev/null
echo ""
echo "--- 看 cef Cookies / 历史 找哪个网站 ---"
SUDO find $PCD/root/.config/cef_user_data -maxdepth 2 -type f 2>/dev/null | head
echo ""
echo "--- linglong (玲珑) 应用商店里装的 app ---"
SUDO ls $PCD/var/lib/linglong/ 2>/dev/null
SUDO find $PCD -maxdepth 5 -path '*linglong*' -name '*.json' 2>/dev/null | head -5
SUDO ls $PCD/persistent/linglong/entries/ 2>/dev/null
SUDO find $PCR/var/lib/linglong/entries -maxdepth 3 2>/dev/null | head -30
echo ""
echo "--- /persistent linglong 应用 (Deepin 23 习惯) ---"
SUDO ls $PCD/persistent/linglong/layers/main/ 2>/dev/null | head -20
SUDO ls $PCR/persistent/linglong/ 2>/dev/null
SUDO find / -path '*linglong*entries*' -name '*.desktop' 2>/dev/null | head -20

echo ""
echo "==========================================" 
echo "uos-ai-assistant 详细（C06/C07）"
echo "=========================================="
SUDO cat $PCR/usr/share/applications/uos-ai-assistant.desktop 2>/dev/null
echo ""
echo "--- uos-ai 配置 ---"
SUDO find $PCD/root/.config $PCD/root/.local -iname '*uos-ai*' 2>/dev/null
SUDO find $PCD -maxdepth 6 -iname '*uos-ai*' 2>/dev/null | head -10
echo ""
SUDO ls $PCD/root/.config/deepin/uos-ai-assistant/ 2>/dev/null
echo ""
echo "--- uos-ai-assistant 用户配置 (apiKey) ---"
SUDO find $PCD/root -name 'uos-ai*' -type f 2>/dev/null | head
SUDO find $PCD/root -name 'deepseek*' -o -name '*config.json' -path '*ai*' 2>/dev/null | head
# UOS AI 配置一般在 .config/deepin/uos-ai-assistant/ 或 .local/share/deepin/uos-ai-assistant/
SUDO ls $PCD/root/.local/share/deepin/uos-ai-assistant/ 2>/dev/null
SUDO ls $PCD/root/.local/share/deepin/ 2>/dev/null

echo ""
echo "==========================================" 
echo "deepin-mail 30 封邮件内容 (找 黄金/AI/TRAE/openai 等)"
echo "=========================================="
MAIL_DIR=$(SUDO find $PCD/root -path '*deepin-mail*' -type d 2>/dev/null | head -3)
echo "$MAIL_DIR"
echo ""
SUDO find $PCD/root -path '*deepin-mail*' -type f 2>/dev/null | head -10
echo ""
SUDO find $PCD/root -path '*deepin-mail*' -type f -name '*.eml' 2>/dev/null | head
SUDO find $PCD/root -path '*deepin-mail*' -name '*.db' 2>/dev/null | head
echo ""
echo "--- 邮件 Subject/From 列表（用 sqlite 读） ---"
DB=$(SUDO find $PCD/root -path '*deepin-mail*' -name '*.db' 2>/dev/null | head -1)
echo "DB=$DB"
if [ -n "$DB" ]; then
  SUDO cp "$DB" /tmp/fic_extract/mail.db
  SUDO chown hjsssr:hjsssr /tmp/fic_extract/mail.db
  echo "tables:"
  sqlite3 /tmp/fic_extract/mail.db ".tables"
  echo ""
  echo "schema:"
  sqlite3 /tmp/fic_extract/mail.db ".schema" 2>&1 | head -50
fi

echo ""
echo "==========================================" 
echo "Foxmail (deepin-wine 装的) - 邮件位置"
echo "=========================================="
SUDO find $PCD -path '*foxmail*' -o -path '*Foxmail*' 2>/dev/null | head -20
SUDO find $PCD/root/.deepinwine $PCD/root/.deepin-wine* -maxdepth 8 -name '*.eml' 2>/dev/null | head
SUDO find $PCD -name 'Foxmail.exe' 2>/dev/null | head

echo ""
echo "==========================================" 
echo "C03 黄金 - 在所有 home/root 下做 grep（含 .config）"
echo "=========================================="
SUDO grep -ral '黄金\|金条\|金店' $PCD/root 2>/dev/null | grep -v '\.cache\|libreoffice\|deepin-app-store' | head -10
SUDO grep -ral 'gold\|usdt' $PCD/root/.config 2>/dev/null | grep -vE 'deepin-app-store|cache|libreoffice|dictionar' | head -10

echo ""
echo "==========================================" 
echo "C08 勒索 - 看 .viminfo / 历史 / 任意奇怪 readme"
echo "=========================================="
SUDO cat $PCD/root/.viminfo 2>/dev/null | head -50

echo ""
echo "==========================================" 
echo "B03 SampleVC.exe 静态串中找密码逻辑"
echo "=========================================="
# u盘和 SampleVC 哪儿
SUDO find /tmp/usb_mnt /tmp/u_mnt -name 'SampleVC*' 2>/dev/null
ls /tmp/fic_extract/usb 2>/dev/null
ls /tmp/fic_extract/sample 2>/dev/null
# 已经 copy 的话
SUDO find / -name 'SampleVC.exe' 2>/dev/null | head
